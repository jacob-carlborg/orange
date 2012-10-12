LIBNAME=orange
DC?=dmd
PREFIX=/usr/local
#Warning, unittests fail with VERSION=release
VERSION?=standard
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

ifeq ("$(VERSION)","release")
	ifeq ("$(DC)","dmd")
		DCFLAGS += -O
	else ifeq ("$(DC)","gdc")
		DCFLAGS += -O3
	endif
else ifeq ("$(VERSION)","debug")
	ifeq ("$(DC)","dmd")
		DCFLAGS += -g
	else ifeq ("$(DC)","gdc")
		DCFLAGS += -g -fdebug
	endif
endif

ifeq ("$(DC)","dmd")
	OUTPUTPREFIX = -of
	LIBCOMMAND = $(DC) -lib $(DCFLAGS) $(OUTPUTPREFIX)$@ $^
	HEADEROPT = -o- -Hf
else ifeq ("$(DC)","gdc")
	OUTPUTPREFIX = -o
	LIBCOMMAND = ar rcs $@ $^
	HEADEROPT = -fintfc-file=
	UNITTESTPREFIX=f
endif

# Everything below this line should be fairly generic (with a few hard-coded things).

OBJ=$(addsuffix .o,$(addprefix $(LIBDIR)/$(LIBNAME)/,$(basename $(SRC))))
HEADER=$(addsuffix .di,$(addprefix import/$(LIBNAME)/,$(basename $(SRC))))
TARGET=$(LIBDIR)/lib$(LIBNAME).a

all: mkdirs $(TARGET) $(HEADER)

install: all
	@mkdir -p $(PREFIX)/lib $(PREFIX)/include/d
	cp $(TARGET) $(PREFIX)/lib/
	cp -r import/$(LIBNAME) $(PREFIX)/include/d

uninstall:
	rm -rf $(PREFIX)/include/d/$(LIBNAME)
	rm -f $(PREFIX)/lib/lib$(LIBNAME).a
	@rmdir -p --ignore-fail-on-non-empty $(PREFIX)/lib $(PREFIX)/include/d 2>/dev/null || true

unittest: ~~cleanunittest
	$(DC) $(DCFLAGS) -$(UNITTESTPREFIX)unittest $(OUTPUTPREFIX)unittest $(addprefix $(LIBNAME)/,$(SRC)) $(UNITTEST) $(LIBNAME)/$(TEST)
	./unittest

clean: ~~cleanunittest
	rm -rf import/ lib/

~~cleanunittest:
	rm -f unittest.o unittest

mkdirs:
	mkdir -p $(addprefix $(LIBDIR)/$(LIBNAME)/,  $(sort $(dir $(SRC))))

$(TARGET): $(OBJ)
	$(LIBCOMMAND)

$(LIBDIR)/$(LIBNAME)/%.o: $(LIBNAME)/%.d
	$(DC) -c $(DCFLAGS) $(OUTPUTPREFIX)$@ $<

import/$(LIBNAME)/%.di: $(LIBNAME)/%.d
	$(DC) -c $(HEADEROPT)$@ $<