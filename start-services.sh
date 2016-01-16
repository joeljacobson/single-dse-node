#!/bin/bash
# @joeljacobson

VERSION="4.8.4"
OPSCENTER="5.2.3"
AGENT="5.2.3"
NODE_OPTS=$1

       # check if java is installed
       echo 'checking java is installed'
       if type -p java ; then
       echo 'found java executable in PATH'
       _java=java
       elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]] ;  then
       echo 'found java executable in JAVA_HOME'
       _java="$JAVA_HOME/bin/java"
       else
       echo "java is not installed "
       exit 1
       fi

       # check if java 8 is installed
       if [[ "$_java" ]]; then
       version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
       echo version "$version"
       if [[ "$version" > "1.7" ]]; then
       echo 'java is installed, proceeding... '
       else
       echo 'java version is lower than 1.7, please upgrade to 1.7 or higher to proceed'
       exit 1
       fi
       fi

    # check if cassandra is present
    if [ ! -f dse.tar.gz ] ; then
    echo "dse $VERSION not found, downloading now..."
    curl -O --user user:pass -L http://downloads.datastax.com/enterprise/dse.tar.gz
    fi

    # check if opscenter is present
    if [ ! -d opscenter-$OPSCENTER ] ; then
    echo "opscenter and agent not found, downloading now..."
    curl -L http://downloads.datastax.com/community/opscenter-$OPSCENTER.tar.gz | tar xz
    fi

    # check if datastax agent is present
    if  [ ! -d datastax-agent-$AGENT ] ; then
    curl -L http://downloads.datastax.com/community/datastax-agent-$AGENT.tar.gz | tar xz
    echo "stomp_interface: 127.0.0.1" >> ./datastax-agent-$AGENT/conf/address.yaml
    fi

    # check if dse has been unpacked
    if [ ! -d dse-$VERSION ] ; then
    echo "unpacking dse-$VERSION"
    pv dse.tar.gz| tar xzf -
    fi

# check if cassandra is running
if ps aux | grep -v grep | grep cass &> /dev/null
then
read -r -p "cassandra is running, do you wish to kill? [y/N]" response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
sudo su root -c "ps -ef | grep 'cassandra' | grep -v grep | awk '{print $2}' | xargs kill | echo 'okay, cassandra was killed...'"
sleep 3
else
exit 1
fi
fi

# if changing the type of node, you must remove the /var/lib/cassandra data
read -r -p "are you changing the type of node? [y/N]" response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
read -r -p "are you okay to lose your data? [y/N]" response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
sudo su root -c "rm -rf /var/lib/cassandra/ &> /dev/null"
sudo su root -c "rm opscenter-5.2.3/conf/clusters/ &> /dev/null"
echo 'data deleted...'
else
echo 'quitting...'
exit 1
fi
fi

# start cassandra
echo 'starting cassandra'
sudo su root -c "dse-$VERSION/bin/dse cassandra $NODE_OPTS &> /dev/null"
sleep 3

# start datastax agent
if ps aux | grep -v grep | datastax &> /dev/null
then
echo 'agent running'
else
echo 'starting datastax-agent'
datastax-agent-$AGENT/bin/datastax-agent &> /dev/null
sleep 3
fi

if ps aux | grep -v grep | opscenter &> /dev/null
then
echo 'opscenter running...'
else
echo 'starting opscenter'
opscenter-$OPSCENTER/bin/opscenter &> /dev/null
sleep 3
echo 'opscenter is on http://127.0.0.1:8888'
fi
