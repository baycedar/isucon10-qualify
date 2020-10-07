package main

import (
	"database/sql"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
	"github.com/labstack/gommon/log"
	"github.com/lib/pq"
	_ "github.com/lib/pq"
)

// Limit is the default max number of result rows
const Limit = 20

// NazotteLimit is the max number of result rows for nazotte queries
const NazotteLimit = 50

var db *sqlx.DB
var pgConnectionData *PgConnectionEnv
var chairSearchCondition ChairSearchCondition
var estateSearchCondition EstateSearchCondition

// InitializeResponse is a response format for /initialize
type InitializeResponse struct {
	Language string `json:"language"`
}

// Chair is a base format for chair data
type Chair struct {
	ID          int64  `db:"id" json:"id"`
	Name        string `db:"name" json:"name"`
	Description string `db:"description" json:"description"`
	Thumbnail   string `db:"thumbnail" json:"thumbnail"`
	Price       int64  `db:"price" json:"price"`
	Height      int64  `db:"height" json:"height"`
	Width       int64  `db:"width" json:"width"`
	Depth       int64  `db:"depth" json:"depth"`
	Color       string `db:"color" json:"color"`
	Features    string `db:"features" json:"features"`
	Kind        string `db:"kind" json:"kind"`
	Popularity  int64  `db:"popularity" json:"-"`
	Stock       int64  `db:"stock" json:"-"`
}

// ChairSearchResponse is a response format for /api/chair/search
type ChairSearchResponse struct {
	Count  int64   `json:"count"`
	Chairs []Chair `json:"chairs"`
}

// ChairListResponse is a response format for a list of chairs
type ChairListResponse struct {
	Chairs []Chair `json:"chairs"`
}

// Estate is a base format for estate data
type Estate struct {
	ID          int64   `db:"id" json:"id"`
	Thumbnail   string  `db:"thumbnail" json:"thumbnail"`
	Name        string  `db:"name" json:"name"`
	Description string  `db:"description" json:"description"`
	Latitude    float64 `db:"latitude" json:"latitude"`
	Longitude   float64 `db:"longitude" json:"longitude"`
	Address     string  `db:"address" json:"address"`
	Rent        int64   `db:"rent" json:"rent"`
	DoorHeight  int64   `db:"door_height" json:"doorHeight"`
	DoorWidth   int64   `db:"door_width" json:"doorWidth"`
	Features    string  `db:"features" json:"features"`
	Popularity  int64   `db:"popularity" json:"-"`
}

// EstateSearchResponse is a response format for /api/estate/search
type EstateSearchResponse struct {
	Count   int64    `json:"count"`
	Estates []Estate `json:"estates"`
}

// EstateListResponse is a response format for a list of estates
type EstateListResponse struct {
	Estates []Estate `json:"estates"`
}

// Coordinate is a struct for 2-D coordinates
type Coordinate struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

// Coordinates is a struct for a 2-D polygon
type Coordinates struct {
	Coordinates []Coordinate `json:"coordinates"`
}

// Range is a base struct for conditions of range queries
type Range struct {
	ID  int64 `json:"id"`
	Min int64 `json:"min"`
	Max int64 `json:"max"`
}

// RangeCondition is a struct to decorate ranges
type RangeCondition struct {
	Prefix string   `json:"prefix"`
	Suffix string   `json:"suffix"`
	Ranges []*Range `json:"ranges"`
}

// ListCondition is a struct for a list of select conditions
type ListCondition struct {
	List []string `json:"list"`
}

// EstateSearchCondition is a struct for conditions of estates
type EstateSearchCondition struct {
	DoorWidth  RangeCondition `json:"doorWidth"`
	DoorHeight RangeCondition `json:"doorHeight"`
	Rent       RangeCondition `json:"rent"`
	Feature    ListCondition  `json:"feature"`
}

// ChairSearchCondition is a struct for conditions of chairs
type ChairSearchCondition struct {
	Width   RangeCondition `json:"width"`
	Height  RangeCondition `json:"height"`
	Depth   RangeCondition `json:"depth"`
	Price   RangeCondition `json:"price"`
	Color   ListCondition  `json:"color"`
	Feature ListCondition  `json:"feature"`
	Kind    ListCondition  `json:"kind"`
}

// PgConnectionEnv is a struct to retain PostgreSQL connection information
type PgConnectionEnv struct {
	Host     string
	Port     string
	User     string
	DBName   string
	Password string
}

// RecordMapper is a struct for a record of query results
type RecordMapper struct {
	Record []string

	offset int
	err    error
}

func (r *RecordMapper) next() (string, error) {
	if r.err != nil {
		return "", r.err
	}
	if r.offset >= len(r.Record) {
		r.err = fmt.Errorf("too many read")
		return "", r.err
	}
	s := r.Record[r.offset]
	r.offset++
	return s, nil
}

// NextInt parses a record into int
func (r *RecordMapper) NextInt() int {
	s, err := r.next()
	if err != nil {
		return 0
	}
	i, err := strconv.Atoi(s)
	if err != nil {
		r.err = err
		return 0
	}
	return i
}

// NextFloat parses a record into float
func (r *RecordMapper) NextFloat() float64 {
	s, err := r.next()
	if err != nil {
		return 0
	}
	f, err := strconv.ParseFloat(s, 64)
	if err != nil {
		r.err = err
		return 0
	}
	return f
}

// NextString parses a record into string
func (r *RecordMapper) NextString() string {
	s, err := r.next()
	if err != nil {
		return ""
	}
	return s
}

// Err returns an error of a record
func (r *RecordMapper) Err() error {
	return r.err
}

// NewPgConnectionEnv returns a connection of PostgreSQL
func NewPgConnectionEnv() *PgConnectionEnv {
	return &PgConnectionEnv{
		Host:     getEnv("PGHOST", "127.0.0.1"),
		Port:     getEnv("PGPORT", "5432"),
		User:     getEnv("PGUSER", "isucon"),
		DBName:   getEnv("PGDATABASE", "isuumo"),
		Password: getEnv("PGPASSWORD", "isucon"),
	}
}

func getEnv(key, defaultValue string) string {
	val := os.Getenv(key)
	if val != "" {
		return val
	}
	return defaultValue
}

//ConnectDB isuumoデータベースに接続する
func (mc *PgConnectionEnv) ConnectDB() (*sqlx.DB, error) {
	dsn := fmt.Sprintf(
		"user=%v password=%v host=%v port=%v dbname=%v sslmode=disable",
		mc.User,
		mc.Password,
		mc.Host,
		mc.Port,
		mc.DBName,
	)
	return sqlx.Open("postgres", dsn)
}

func init() {
	jsonText, err := ioutil.ReadFile("../fixture/chair_condition.json")
	if err != nil {
		fmt.Printf("%v\n", err)
		os.Exit(1)
	}
	json.Unmarshal(jsonText, &chairSearchCondition)

	jsonText, err = ioutil.ReadFile("../fixture/estate_condition.json")
	if err != nil {
		fmt.Printf("%v\n", err)
		os.Exit(1)
	}
	json.Unmarshal(jsonText, &estateSearchCondition)
}

func main() {
	// Echo instance
	e := echo.New()
	e.Debug = false
	e.Logger.SetLevel(log.WARN)

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	// Initialize
	e.POST("/initialize", initialize)

	// Chair Handler
	e.GET("/api/chair/:id", getChairDetail)
	e.POST("/api/chair", postChair)
	e.GET("/api/chair/search", searchChairs)
	e.GET("/api/chair/low_priced", getLowPricedChair)
	e.GET("/api/chair/search/condition", getChairSearchCondition)
	e.POST("/api/chair/buy/:id", buyChair)

	// Estate Handler
	e.GET("/api/estate/:id", getEstateDetail)
	e.POST("/api/estate", postEstate)
	e.GET("/api/estate/search", searchEstates)
	e.GET("/api/estate/low_priced", getLowPricedEstate)
	e.POST("/api/estate/req_doc/:id", postEstateRequestDocument)
	e.POST("/api/estate/nazotte", searchEstateNazotte)
	e.GET("/api/estate/search/condition", getEstateSearchCondition)
	e.GET("/api/recommended_estate/:id", searchRecommendedEstateWithChair)

	pgConnectionData = NewPgConnectionEnv()

	var err error
	db, err = pgConnectionData.ConnectDB()
	if err != nil {
		e.Logger.Fatalf("DB connection failed : %v", err)
	}
	db.SetMaxOpenConns(10)
	defer db.Close()

	// Start server
	serverPort := fmt.Sprintf(":%v", getEnv("SERVER_PORT", "1323"))
	e.Logger.Fatal(e.Start(serverPort))
}

func initialize(c echo.Context) error {
	psqlDir := filepath.Join("..", "psql")

	absPath, _ := filepath.Abs(psqlDir)
	cmdStr := fmt.Sprintf("%v/init.sh", absPath)
	if err := exec.Command("bash", cmdStr).Run(); err != nil {
		c.Logger().Errorf("Initialize script error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	return c.JSON(http.StatusOK, InitializeResponse{
		Language: "go",
	})
}

func getChairDetail(c echo.Context) error {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.Echo().Logger.Errorf("Request parameter \"id\" parse error : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	chair := Chair{}
	query := `
SELECT
  id,
  name,
  description,
  thumbnail,
  price,
  height,
  width,
  depth,
  color,
  features,
  kind,
  popularity,
  stock
FROM
  chair
WHERE
  id = $1
`
	err = db.Get(&chair, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			c.Echo().Logger.Infof("requested id's chair not found : %v", id)
			return c.NoContent(http.StatusNotFound)
		}
		c.Echo().Logger.Errorf("Failed to get the chair from id : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	} else if chair.Stock <= 0 {
		c.Echo().Logger.Infof("requested id's chair is sold out : %v", id)
		return c.NoContent(http.StatusNotFound)
	}

	return c.JSON(http.StatusOK, chair)
}

func postChair(c echo.Context) error {
	header, err := c.FormFile("chairs")
	if err != nil {
		c.Logger().Errorf("failed to get form file: %v", err)
		return c.NoContent(http.StatusBadRequest)
	}
	f, err := header.Open()
	if err != nil {
		c.Logger().Errorf("failed to open form file: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	defer f.Close()
	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		c.Logger().Errorf("failed to read csv: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	tx, err := db.Begin()
	if err != nil {
		c.Logger().Errorf("failed to begin tx: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	defer tx.Rollback()

	// bulk imports
	stmt, err := tx.Prepare(pq.CopyIn(
		"chair",
		"id",
		"name",
		"description",
		"thumbnail",
		"price",
		"height",
		"width",
		"depth",
		"color",
		"features",
		"kind",
		"popularity",
		"stock",
	))
	if err != nil {
		c.Logger().Errorf("failed to prepare copy: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	for _, row := range records {
		rm := RecordMapper{Record: row}
		id := rm.NextInt()
		name := rm.NextString()
		description := rm.NextString()
		thumbnail := rm.NextString()
		price := rm.NextInt()
		height := rm.NextInt()
		width := rm.NextInt()
		depth := rm.NextInt()
		color := rm.NextString()
		features := rm.NextString()
		kind := rm.NextString()
		popularity := rm.NextInt()
		stock := rm.NextInt()
		if err := rm.Err(); err != nil {
			c.Logger().Errorf("failed to read record: %v", err)
			return c.NoContent(http.StatusBadRequest)
		}
		_, err = stmt.Exec(
			id,
			name,
			description,
			thumbnail,
			price,
			height,
			width,
			depth,
			color,
			features,
			kind,
			popularity,
			stock,
		)
		if err != nil {
			c.Logger().Errorf("failed to insert chair: %v", err)
			return c.NoContent(http.StatusInternalServerError)
		}
	}
	if err := stmt.Close(); err != nil {
		c.Logger().Errorf("failed to close copy: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	if err := tx.Commit(); err != nil {
		c.Logger().Errorf("failed to commit tx: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	return c.NoContent(http.StatusCreated)
}

func searchChairs(c echo.Context) error {
	conditions := make([]string, 0)
	params := make([]interface{}, 0)

	if c.QueryParam("priceRangeId") != "" {
		chairPrice, err := getRange(chairSearchCondition.Price, c.QueryParam("priceRangeId"))
		if err != nil {
			c.Echo().Logger.Infof("priceRangeID invalid, %v : %v", c.QueryParam("priceRangeId"), err)
			return c.NoContent(http.StatusBadRequest)
		}

		if chairPrice.Min != -1 {
			conditions = append(conditions, "price >= $"+strconv.Itoa(len(params)+1))
			params = append(params, chairPrice.Min)
		}
		if chairPrice.Max != -1 {
			conditions = append(conditions, "price < $"+strconv.Itoa(len(params)+1))
			params = append(params, chairPrice.Max)
		}
	}

	if c.QueryParam("heightRangeId") != "" {
		chairHeight, err := getRange(chairSearchCondition.Height, c.QueryParam("heightRangeId"))
		if err != nil {
			c.Echo().Logger.Infof("heightRangeIf invalid, %v : %v", c.QueryParam("heightRangeId"), err)
			return c.NoContent(http.StatusBadRequest)
		}

		if chairHeight.Min != -1 {
			conditions = append(conditions, "height >= $"+strconv.Itoa(len(params)+1))
			params = append(params, chairHeight.Min)
		}
		if chairHeight.Max != -1 {
			conditions = append(conditions, "height < $"+strconv.Itoa(len(params)+1))
			params = append(params, chairHeight.Max)
		}
	}

	if c.QueryParam("widthRangeId") != "" {
		chairWidth, err := getRange(chairSearchCondition.Width, c.QueryParam("widthRangeId"))
		if err != nil {
			c.Echo().Logger.Infof("widthRangeID invalid, %v : %v", c.QueryParam("widthRangeId"), err)
			return c.NoContent(http.StatusBadRequest)
		}

		if chairWidth.Min != -1 {
			conditions = append(conditions, "width >= $"+strconv.Itoa(len(params)+1))
			params = append(params, chairWidth.Min)
		}
		if chairWidth.Max != -1 {
			conditions = append(conditions, "width < $"+strconv.Itoa(len(params)+1))
			params = append(params, chairWidth.Max)
		}
	}

	if c.QueryParam("depthRangeId") != "" {
		chairDepth, err := getRange(chairSearchCondition.Depth, c.QueryParam("depthRangeId"))
		if err != nil {
			c.Echo().Logger.Infof("depthRangeId invalid, %v : %v", c.QueryParam("depthRangeId"), err)
			return c.NoContent(http.StatusBadRequest)
		}

		if chairDepth.Min != -1 {
			conditions = append(conditions, "depth >= $"+strconv.Itoa(len(params)+1))
			params = append(params, chairDepth.Min)
		}
		if chairDepth.Max != -1 {
			conditions = append(conditions, "depth < $"+strconv.Itoa(len(params)+1))
			params = append(params, chairDepth.Max)
		}
	}

	if c.QueryParam("kind") != "" {
		conditions = append(conditions, "kind = $"+strconv.Itoa(len(params)+1))
		params = append(params, c.QueryParam("kind"))
	}

	if c.QueryParam("color") != "" {
		conditions = append(conditions, "color = $"+strconv.Itoa(len(params)+1))
		params = append(params, c.QueryParam("color"))
	}

	if c.QueryParam("features") != "" {
		for _, f := range strings.Split(c.QueryParam("features"), ",") {
			conditions = append(conditions, "features LIKE CONCAT('%', '"+f+"', '%')")
			//params = append(params, f)
		}
	}

	if len(conditions) == 0 {
		c.Echo().Logger.Infof("Search condition not found")
		return c.NoContent(http.StatusBadRequest)
	}

	conditions = append(conditions, "stock > 0")

	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		c.Logger().Infof("Invalid format page parameter : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	perPage, err := strconv.Atoi(c.QueryParam("perPage"))
	if err != nil {
		c.Logger().Infof("Invalid format perPage parameter : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	searchQuery := `
SELECT
  id,
  name,
  description,
  thumbnail,
  price,
  height,
  width,
  depth,
  color,
  features,
  kind,
  popularity,
  stock
FROM
  chair
WHERE
`
	countQuery := `
SELECT
  COUNT(*) as count
FROM
  chair
WHERE
`
	searchCondition := strings.Join(conditions, "\n  AND ")
	limitOffset := `
ORDER BY
  popularity DESC,
  id ASC
LIMIT
  $` + strconv.Itoa(len(params)+1) + `
OFFSET
  $` + strconv.Itoa(len(params)+2) + `
`

	var res ChairSearchResponse
	err = db.Get(&res.Count, countQuery+searchCondition, params...)
	if err != nil {
		c.Logger().Errorf("searchChairs DB execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	chairs := []Chair{}
	params = append(params, perPage, page*perPage)
	err = db.Select(&chairs, searchQuery+searchCondition+limitOffset, params...)
	if err != nil {
		if err == sql.ErrNoRows {
			return c.JSON(http.StatusOK, ChairSearchResponse{Count: 0, Chairs: []Chair{}})
		}
		c.Logger().Errorf("searchChairs DB execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	res.Chairs = chairs

	return c.JSON(http.StatusOK, res)
}

func buyChair(c echo.Context) error {
	m := echo.Map{}
	if err := c.Bind(&m); err != nil {
		c.Echo().Logger.Infof("post buy chair failed : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	_, ok := m["email"].(string)
	if !ok {
		c.Echo().Logger.Info("post buy chair failed : email not found in request body")
		return c.NoContent(http.StatusBadRequest)
	}

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.Echo().Logger.Infof("post buy chair failed : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	tx, err := db.Beginx()
	if err != nil {
		c.Echo().Logger.Errorf("failed to create transaction : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	defer tx.Rollback()

	row := tx.QueryRowx(`
UPDATE
  chair
SET
  stock = stock - 1
WHERE
  id = $1
  AND stock > 0
RETURNING
  id
`,
		id,
	)
	//if err != nil {
	//	c.Echo().Logger.Errorf("chair stock update failed : %v", err)
	//	return c.NoContent(http.StatusInternalServerError)
	//}
	var returningID int
	err = row.Scan(&returningID)
	if err != nil {
		if err == sql.ErrNoRows {
			c.Echo().Logger.Infof("buyChair chair id \"%v\" not found", id)
			return c.NoContent(http.StatusNotFound)
		}
		c.Echo().Logger.Errorf("DB Execution Error: on getting a chair by id : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	err = tx.Commit()
	if err != nil {
		c.Echo().Logger.Errorf("transaction commit error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	return c.NoContent(http.StatusOK)
}

func getChairSearchCondition(c echo.Context) error {
	return c.JSON(http.StatusOK, chairSearchCondition)
}

func getLowPricedChair(c echo.Context) error {
	var chairs []Chair
	query := `
SELECT
  id,
  name,
  description,
  thumbnail,
  price,
  height,
  width,
  depth,
  color,
  features,
  kind,
  popularity,
  stock
FROM
  chair
WHERE
  stock > 0
ORDER BY
  price ASC,
  id ASC
LIMIT
  $1
`
	err := db.Select(&chairs, query, Limit)
	if err != nil {
		if err == sql.ErrNoRows {
			c.Logger().Error("getLowPricedChair not found")
			return c.JSON(http.StatusOK, ChairListResponse{[]Chair{}})
		}
		c.Logger().Errorf("getLowPricedChair DB execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	return c.JSON(http.StatusOK, ChairListResponse{Chairs: chairs})
}

func getEstateDetail(c echo.Context) error {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.Echo().Logger.Infof("Request parameter \"id\" parse error : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	var estate Estate
	err = db.Get(
		&estate, `
SELECT
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity
FROM
  estate
WHERE
  id = $1
`,
		id,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			c.Echo().Logger.Infof("getEstateDetail estate id %v not found", id)
			return c.NoContent(http.StatusNotFound)
		}
		c.Echo().Logger.Errorf("Database Execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	return c.JSON(http.StatusOK, estate)
}

func getRange(cond RangeCondition, rangeID string) (*Range, error) {
	RangeIndex, err := strconv.Atoi(rangeID)
	if err != nil {
		return nil, err
	}

	if RangeIndex < 0 || len(cond.Ranges) <= RangeIndex {
		return nil, fmt.Errorf("Unexpected Range ID")
	}

	return cond.Ranges[RangeIndex], nil
}

func postEstate(c echo.Context) error {
	header, err := c.FormFile("estates")
	if err != nil {
		c.Logger().Errorf("failed to get form file: %v", err)
		return c.NoContent(http.StatusBadRequest)
	}
	f, err := header.Open()
	if err != nil {
		c.Logger().Errorf("failed to open form file: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	defer f.Close()
	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		c.Logger().Errorf("failed to read csv: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	tx, err := db.Begin()
	if err != nil {
		c.Logger().Errorf("failed to begin tx: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	defer tx.Rollback()

	// bulk imports
	stmt, err := tx.Prepare(pq.CopyIn(
		"estate",
		"id",
		"name",
		"description",
		"thumbnail",
		"address",
		"latitude",
		"longitude",
		"rent",
		"door_height",
		"door_width",
		"features",
		"popularity",
	))
	if err != nil {
		c.Logger().Errorf("failed to prepare copy: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	for _, row := range records {
		rm := RecordMapper{Record: row}
		id := rm.NextInt()
		name := rm.NextString()
		description := rm.NextString()
		thumbnail := rm.NextString()
		address := rm.NextString()
		latitude := rm.NextFloat()
		longitude := rm.NextFloat()
		rent := rm.NextInt()
		doorHeight := rm.NextInt()
		doorWidth := rm.NextInt()
		features := rm.NextString()
		popularity := rm.NextInt()
		if err := rm.Err(); err != nil {
			c.Logger().Errorf("failed to read record: %v", err)
			return c.NoContent(http.StatusBadRequest)
		}
		_, err = stmt.Exec(
			id,
			name,
			description,
			thumbnail,
			address,
			latitude,
			longitude,
			rent,
			doorHeight,
			doorWidth,
			features,
			popularity,
		)
		if err != nil {
			c.Logger().Errorf("failed to insert estate: %v", err)
			return c.NoContent(http.StatusInternalServerError)
		}
	}
	if err := stmt.Close(); err != nil {
		c.Logger().Errorf("failed to close copy: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	if err := tx.Commit(); err != nil {
		c.Logger().Errorf("failed to commit tx: %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	return c.NoContent(http.StatusCreated)
}

func searchEstates(c echo.Context) error {
	conditions := make([]string, 0)
	params := make([]interface{}, 0)

	if c.QueryParam("doorHeightRangeId") != "" {
		doorHeight, err := getRange(
			estateSearchCondition.DoorHeight,
			c.QueryParam("doorHeightRangeId"),
		)
		if err != nil {
			c.Echo().Logger.Infof(
				"doorHeightRangeID invalid, %v : %v",
				c.QueryParam("doorHeightRangeId"),
				err,
			)
			return c.NoContent(http.StatusBadRequest)
		}

		if doorHeight.Min != -1 {
			conditions = append(conditions, "door_height >= $"+strconv.Itoa(len(params)+1))
			params = append(params, doorHeight.Min)
		}
		if doorHeight.Max != -1 {
			conditions = append(conditions, "door_height < $"+strconv.Itoa(len(params)+1))
			params = append(params, doorHeight.Max)
		}
	}

	if c.QueryParam("doorWidthRangeId") != "" {
		doorWidth, err := getRange(
			estateSearchCondition.DoorWidth,
			c.QueryParam("doorWidthRangeId"),
		)
		if err != nil {
			c.Echo().Logger.Infof(
				"doorWidthRangeID invalid, %v : %v",
				c.QueryParam("doorWidthRangeId"),
				err,
			)
			return c.NoContent(http.StatusBadRequest)
		}

		if doorWidth.Min != -1 {
			conditions = append(conditions, "door_width >= $"+strconv.Itoa(len(params)+1))
			params = append(params, doorWidth.Min)
		}
		if doorWidth.Max != -1 {
			conditions = append(conditions, "door_width < $"+strconv.Itoa(len(params)+1))
			params = append(params, doorWidth.Max)
		}
	}

	if c.QueryParam("rentRangeId") != "" {
		estateRent, err := getRange(
			estateSearchCondition.Rent,
			c.QueryParam("rentRangeId"),
		)
		if err != nil {
			c.Echo().Logger.Infof(
				"rentRangeID invalid, %v : %v",
				c.QueryParam("rentRangeId"),
				err,
			)
			return c.NoContent(http.StatusBadRequest)
		}

		if estateRent.Min != -1 {
			conditions = append(conditions, "rent >= $"+strconv.Itoa(len(params)+1))
			params = append(params, estateRent.Min)
		}
		if estateRent.Max != -1 {
			conditions = append(conditions, "rent < $"+strconv.Itoa(len(params)+1))
			params = append(params, estateRent.Max)
		}
	}

	if c.QueryParam("features") != "" {
		for _, f := range strings.Split(c.QueryParam("features"), ",") {
			conditions = append(
				conditions,
				"features LIKE CONCAT('%', '"+f+"', '%')",
			)
			//params = append(params, f)
		}
	}

	if len(conditions) == 0 {
		c.Echo().Logger.Infof("searchEstates search condition not found")
		return c.NoContent(http.StatusBadRequest)
	}

	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		c.Logger().Infof("Invalid format page parameter : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	perPage, err := strconv.Atoi(c.QueryParam("perPage"))
	if err != nil {
		c.Logger().Infof("Invalid format perPage parameter : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	searchQuery := `
SELECT
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity
FROM
  estate
WHERE
`
	countQuery := `
SELECT
  COUNT(*) AS count
FROM
  estate
WHERE
`
	searchCondition := strings.Join(conditions, "\n  AND ")
	limitOffset := `
ORDER BY
  popularity DESC,
  id ASC
LIMIT
  $` + strconv.Itoa(len(params)+1) + `
OFFSET
  $` + strconv.Itoa(len(params)+2) + `
`

	var res EstateSearchResponse
	err = db.Get(&res.Count, countQuery+searchCondition, params...)
	if err != nil {
		c.Logger().Errorf("searchEstates DB execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	estates := []Estate{}
	params = append(params, perPage, page*perPage)
	err = db.Select(&estates, searchQuery+searchCondition+limitOffset, params...)
	if err != nil {
		if err == sql.ErrNoRows {
			return c.JSON(http.StatusOK, EstateSearchResponse{Count: 0, Estates: []Estate{}})
		}
		c.Logger().Errorf("searchEstates DB execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	res.Estates = estates

	return c.JSON(http.StatusOK, res)
}

func getLowPricedEstate(c echo.Context) error {
	estates := make([]Estate, 0, Limit)
	query := `
SELECT
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity
FROM
  estate
ORDER BY
  rent ASC,
  id ASC
LIMIT
  $1
`
	err := db.Select(&estates, query, Limit)
	if err != nil {
		if err == sql.ErrNoRows {
			c.Logger().Error("getLowPricedEstate not found")
			return c.JSON(http.StatusOK, EstateListResponse{[]Estate{}})
		}
		c.Logger().Errorf("getLowPricedEstate DB execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	return c.JSON(http.StatusOK, EstateListResponse{Estates: estates})
}

func searchRecommendedEstateWithChair(c echo.Context) error {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.Logger().Infof("Invalid format searchRecommendedEstateWithChair id : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	// chair := Chair{}
	// query := `SELECT * FROM chair WHERE id = ?`
	// err = db.Get(&chair, query, id)
	// if err != nil {
	// 	if err == sql.ErrNoRows {
	// 		c.Logger().Infof("Requested chair id \"%v\" not found", id)
	// 		return c.NoContent(http.StatusBadRequest)
	// 	}
	// 	c.Logger().Errorf("Database execution error : %v", err)
	// 	return c.NoContent(http.StatusInternalServerError)
	// }

	var estates []Estate
	// w := chair.Width
	// h := chair.Height
	// d := chair.Depth
	query := `
SELECT
  e.id,
  e.name,
  e.description,
  e.thumbnail,
  e.address,
  e.latitude,
  e.longitude,
  e.rent,
  e.door_height,
  e.door_width,
  e.features,
  e.popularity
FROM
  estate AS e,
  chair AS c
WHERE
  c.id = $1
  AND (
    (e.door_width >= c.width AND e.door_height >= c.height)
    OR (e.door_width >= c.width AND e.door_height >= c.depth)
    OR (e.door_width >= c.height AND e.door_height >= c.width)
    OR (e.door_width >= c.height AND e.door_height >= c.depth)
    OR (e.door_width >= c.depth AND e.door_height >= c.width)
    OR (e.door_width >= c.depth AND e.door_height >= c.height)
  )
ORDER BY
  popularity DESC,
  id ASC
LIMIT
  $2
`
	err = db.Select(&estates, query, id, Limit)
	if err != nil {
		if err == sql.ErrNoRows {
			return c.JSON(http.StatusOK, EstateListResponse{[]Estate{}})
		}
		c.Logger().Errorf("Database execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	return c.JSON(http.StatusOK, EstateListResponse{Estates: estates})
}

func searchEstateNazotte(c echo.Context) error {
	coordinates := Coordinates{}
	err := c.Bind(&coordinates)
	if err != nil {
		c.Echo().Logger.Infof("post search estate nazotte failed : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	if len(coordinates.Coordinates) == 0 {
		return c.NoContent(http.StatusBadRequest)
	}

	var re EstateSearchResponse
	re.Estates = []Estate{}
	query := `
SELECT
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity
FROM
  estate
WHERE
  ST_Contains(
    ST_PolygonFromText(` + coordinates.coordinatesToText() + `),
    geom_coords
  )
ORDER BY
  popularity DESC,
  id ASC
LIMIT
  $1
`

	err = db.Select(
		&re.Estates,
		query,
		//		coordinates.coordinatesToText(),
		NazotteLimit,
	)
	if err == sql.ErrNoRows {
		c.Echo().Logger.Infof("select * from estate where latitude ...", err)
		return c.JSON(http.StatusOK, EstateSearchResponse{Count: 0, Estates: []Estate{}})
	} else if err != nil {
		c.Echo().Logger.Errorf("database execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}
	re.Count = int64(len(re.Estates))

	return c.JSON(http.StatusOK, re)
}

func postEstateRequestDocument(c echo.Context) error {
	m := echo.Map{}
	if err := c.Bind(&m); err != nil {
		c.Echo().Logger.Infof("post request document failed : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	_, ok := m["email"].(string)
	if !ok {
		c.Echo().Logger.Info("post request document failed : email not found in request body")
		return c.NoContent(http.StatusBadRequest)
	}

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.Echo().Logger.Infof("post request document failed : %v", err)
		return c.NoContent(http.StatusBadRequest)
	}

	estate := Estate{}
	query := `
SELECT
  id
FROM
  estate
WHERE
  id = $1
`
	err = db.Get(&estate, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return c.NoContent(http.StatusNotFound)
		}
		c.Logger().Errorf("postEstateRequestDocument DB execution error : %v", err)
		return c.NoContent(http.StatusInternalServerError)
	}

	return c.NoContent(http.StatusOK)
}

func getEstateSearchCondition(c echo.Context) error {
	return c.JSON(http.StatusOK, estateSearchCondition)
}

func (cs Coordinates) coordinatesToText() string {
	points := make([]string, 0, len(cs.Coordinates))
	for _, c := range cs.Coordinates {
		points = append(points, fmt.Sprintf("%f %f", c.Longitude, c.Latitude))
	}
	return fmt.Sprintf("'POLYGON((%s))'", strings.Join(points, ","))
}
