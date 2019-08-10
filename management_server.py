#!/usr/bin/env python3

import os, sys, subprocess, time, json, urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

def runLocally(commandString):
  p = subprocess.Popen(commandString, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
  output = b""
  for line in p.stdout:
    output += line
  return output

class RequestHandler(BaseHTTPRequestHandler):
  def do_GET(self):
    self.send_response(200)
    self.send_header('Access-Control-Allow-Origin','*')
    self.send_header('Access-Control-Allow-Methods','GET')
    self.send_header('Content-type','text/json')
    self.end_headers()
    if self.path == "/minecraft-status":
      status = runLocally("~/scripts/minecraft_get_status.sh")
      self.wfile.write(bytes(str(status, 'utf-8'), 'utf-8'))
    if self.path == "/map-status":
      response = urllib.request.urlopen("http://127.0.0.1/overviewer.js")
      status = response.status
      self.wfile.write(bytes('{{"status":{}}}'.format(status), 'utf-8'))
    return

def run():
  print('Starting API server...')
  httpd = HTTPServer(('0.0.0.0', 5000), RequestHandler)
  print('Running API server...')
  httpd.serve_forever()

try:
  run()
except Exception as e:
  print(e)
