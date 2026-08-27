#!/bin/bash

spawn-fcgi -p 8080 /app/server
nginx -g "daemon off;"