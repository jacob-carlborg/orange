mkdir -p docs

dmd -c -Dddocs -D candydoc/candy.ddoc modules.ddoc \
orange/core/*.d \
orange/serialization/*.d \
orange/serialization/archives/*.d \
orange/test/*.d \
orange/util/*.d \
orange/util/collection/*.d \
orange/xml/*.d

ln -s -f ../candydoc docs/candydoc