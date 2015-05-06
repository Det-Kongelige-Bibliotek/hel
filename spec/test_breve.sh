#!/usr/bin/env bash
# Test script for running the sample breve import
set -o nounset
set -o errexit

rake adl:clean
rake breve:create_activity
rake breve:import_from_path['spec/fixtures/breve/001541111_000']
rake environment resque:work RAILS_ENV=development QUEUE=*
