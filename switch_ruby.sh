#!/bin/bash
export RUBIES=/Users/donnahedley/.rubies
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh
chruby ruby-3.3.5
exec "$@"
