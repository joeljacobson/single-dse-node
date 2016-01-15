#!/bin/bash 

sudo -i ps -ef | grep 'cassandra\|datastax\|opscenter' | grep -v grep | awk '{print $2}' | xargs kill | echo 'killing processes...'
sleep 3
