Direct service to service calls 
(these leak ports and leak which service serves which path)i

------------------------------
gatekeeper -> shoreline
jellyfish -> gatekeeper
jellyfish-> seagull
jellyfish-> shoreline
shoreline -> gatekeeper
shoreline -> highwater
hydrophone -> shoreline
hydrophone -> seagull
hydrophone -> gatekeeper
hydrophone -> highwater
messageapi -> gatekeeper
messageapi -> highwater
messageapi -> seagull
messageapi -> shoreline
highwater -> shoreline
seagull -> gatekeeper
seagull -> highwater
seagull -> shoreline
tidewhisperer -> auth
tidewhisperer -> gatekeeper
tidewhisperer -> seagull
tidewhisperer -> shoreline

Prefix removal
----
user
  /userservices/

highwater - phase on PR done
  /metrics/

messageapi - phase one PR done
  /message/

hydrophone - phase one PR done
  /confirm/

data
  /dataservices

tidewhisperer - phase one PR done
  /data/

seagull - phase one PR done
  /metadata/



