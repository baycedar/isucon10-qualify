# #!/bin/bash
set -uex -o pipefail
export LC_ALL=C

cd ${HOME}

# install packages
sudo apt install -y \
  git \
  wget \
  vim \
  curl \
  dnsutils \
  net-tools \
  bash-completion \
  silversearcher-ag \
  unzip \
  nginx \
  dstat \
  tcpdump \
  htop \
  fio
echo "apt install done."

# improve prompt
cat << 'EOF' >> ~/.bashrc

# modify prompt
if type __git_ps1 > /dev/null 2>&1 ; then
  export GIT_PS1_SHOWDIRTYSTATE=true
  export GIT_PS1_SHOWSTASHSTATE=true
  export GIT_PS1_SHOWUNTRACKEDFILES=true
  export GIT_PS1_SHOWUPSTREAM="auto"
  export GIT_PS1_SHOWCOLORHINTS=true
fi
export PS1='[\e[01;32m\u@\h\e[0;00m:\w\e[01;31m$(__git_ps1)\e[0;00m \t EXIT=$?] \n\$ '
EOF
echo "a prompt setting is updated."

# add a user to adm group
sudo usermod -aG adm `id -un`
echo "add a user to adm group"

# pt-query-digest
wget -q https://github.com/percona/percona-toolkit/archive/3.0.5-test.tar.gz
tar zxvf 3.0.5-test.tar.gz >> /dev/null
rm 3.0.5-test.tar.gz
cat << 'EOF' >> ${HOME}/.bashrc

# set PATH for pt-query-digest
export PATH="${PATH}:${HOME}/percona-toolkit-3.0.5-test/bin"
EOF
echo "`${HOME}/percona-toolkit-3.0.5-test/bin/pt-query-digest --version` install done."

# mysqldumpslow
echo `which mysqldumpslow`

# kataribe
export GOPATH=${HOME}/go
go get -u github.com/matsuu/kataribe
cat << 'EOF' >> ${HOME}/.bashrc

# set PATH for kataribe
export GOPATH="${HOME}/go"
export PATH="${PATH}:${GOPATH}/bin"
EOF
echo "kataribe install done."

# set Git config
git config --global user.name "`hostname`"
git config --global user.email "isucon@example.com"
git config --global user.name
git config --global user.email
ssh-keygen -q -t ed25519 -f "${HOME}/.ssh/git_ed25519" -N ""
cat << EOF >> ${HOME}/.ssh/config

Host github.com
  User git
  IdentityFile ${HOME}/.ssh/git_ed25519
EOF
cat ${HOME}/.ssh/git_ed25519.pub
