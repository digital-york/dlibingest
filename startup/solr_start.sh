#!/bin/bash
# bin/solr delete -c 
solr_wrapper --persist -d ../solr/config --collection_name hydra-development --version 6.2.0 --instance_directory ~/tmp/solr
#solr_wrapper --persist -d solr/config --version 6.1.0 --instance_directory tmp/solr
