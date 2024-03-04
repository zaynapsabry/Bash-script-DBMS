#!/bin/bash

function directory_exists {
  if [ -d $1 ]; then
    return 0
  else
    return 1
  fi
}

function file_exists {
  if [ -f $1 ]; then
    return 0
  else
    return 1
  fi
}


