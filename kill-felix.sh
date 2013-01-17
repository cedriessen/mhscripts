#!/bin/sh
ps auxwww|grep felix.jar|awk '{print $2}'|xargs kill -9
