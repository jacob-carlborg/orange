LIBNAME=orange
DC=dmd
PREFIX=/usr/local
LIBDIR=lib/$(MODEL)
ARCH=$(shell arch || uname -m)

SRC=core/io.d \
	core/string.d \
	core/_.d \
	serialization/Events.d \
	serialization/RegisterWrapper.d \
	serialization/Serializable.d \
	serialization/SerializationException.d \
	serialization/Serializer.d \
	serialization/_.d \
	serialization/archives/Archive.d \
	serialization/archives/XmlArchive.d \
	serialization/archives/_.d \
	util/CTFE.d \
	util/Reflection.d \
	util/Traits.d \
	util/Use.d \
	util/_.d \
	util/collection/Array.d \
	util/collection/_.d \
	xml/PhobosXml.d \
	xml/XmlDocument.d \
	xml/_.d

UNITTEST=tests/Array.d \
	tests/AssociativeArray.d \
	tests/AssociativeArrayReference.d \
	tests/BaseClass.d \
	tests/Custom.d \
	tests/Enum.d \
	tests/Event.d \
	tests/Events.d \
	tests/NonIntrusive.d \
	tests/NonSerialized.d \
	tests/Object.d \
	tests/OverrideSerializer.d \
	tests/Pointer.d \
	tests/Primitive.d \
	tests/Slice.d \
	tests/String.d \
	tests/Struct.d \
	tests/Subclass.d \
	tests/Typedef.d \
	tests/unittest.d \
	tests/Util.d

TEST=test/UnitTester.d

ifdef MODEL
	DCFLAGS=-m$(MODEL)
else ifeq ("$(ARCH)", "x86_64")
	DCFLAGS=-m64
	override MODEL=64
else
	DCFLAGS=-m32
	override MODEL=32
endif

# Everything below this line should be fairly generic (with a few hard-coded things).

OBJ=$(addsuffix .o,$(addprefix $(LIBDIR)/$(LIBNAME)/,$(basename $(SRC))))
HEADER=$(addsuffix .di,$(addprefix import/$(LIBNAME)/,$(basename $(SRC))))
TARGET=$(LIBDIR)/lib$(LIBNAME).a

all: $(TARGET) $(HEADER)

install: all
	@mkdir -p $(PREFIX)/lib/orange $(PREFIX)/include/d
	cp $(TARGET) $(PREFIX)/lib/orange
	cp -r import/$(LIBNAME) $(PREFIX)/include/d
	@echo =========================================================================
	@echo To compile with \"orange\" library:
	@echo $$ dmd -I/usr/local/include/d -L-L/usr/local/lib/orange -L-lorange myapp.d
	@echo =========================================================================

uninstall:
	rm -f $(PREFIX)/lib/orange/lib$(LIBNAME).a
	rm -rf $(PREFIX)/include/d/$(LIBNAME)
	@rmdir -p --ignore-fail-on-non-empty $(PREFIX)/lib/orange $(PREFIX)/include/d 2>/dev/null || true

unittest: ~~cleanunittest
	$(DC) $(DCFLAGS) -unittest -ofunittest $(addprefix $(LIBNAME)/,$(SRC)) $(UNITTEST) $(LIBNAME)/$(TEST)
	./unittest

clean: ~~cleanunittest
	rm -rf import/ lib/

~~cleanunittest:
	rm -f unittest.o unittest

$(TARGET): $(OBJ)
	$(DC) -lib $(DCFLAGS) -of$@ $^

$(LIBDIR)/$(LIBNAME)/%.o: $(LIBNAME)/%.d
	$(DC) -c $(DCFLAGS) -of$@ $<

import/$(LIBNAME)/%.di: $(LIBNAME)/%.d
	$(DC) -c -o- -Hf$@ $<
