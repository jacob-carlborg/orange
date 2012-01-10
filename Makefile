LIBNAME=orange
DC=dmd
PREFIX=/usr/local
LIBDIR=lib/$(MODEL)
DOCDIR=doc
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
DOCLIST=$(shell echo $(sort $(addprefix $(LIBNAME)/,$(SRC) $(TEST))) | sed 's; ;\n;g' | sed '/_.d/d') 

all: $(TARGET) $(HEADER)

install: all
	@mkdir -p $(PREFIX)/lib $(PREFIX)/include/d
	cp $(TARGET) $(PREFIX)/lib/
	cp -r import/$(LIBNAME) $(PREFIX)/include/d

uninstall:
	rm -rf $(PREFIX)/include/d/$(LIBNAME)
	rm -f $(PREFIX)/lib/lib$(LIBNAME).a
	@rmdir -p --ignore-fail-on-non-empty $(PREFIX)/lib $(PREFIX)/include/d 2>/dev/null || true

unittest: ~cleanunittest
	$(DC) $(DCFLAGS) -unittest -ofunittest $(addprefix $(LIBNAME)/,$(SRC)) $(UNITTEST) $(LIBNAME)/$(TEST)
	./unittest

doc: ~candydoc

clean: ~cleanunittest
	rm -rf import/ lib/
	rm -f $(DOCDIR)/*.html
	rm -f $(DOCDIR)/candydoc/modules.ddoc

~candydoc:
	@echo "MODULES = " > $(DOCDIR)/candydoc/modules.ddoc
	@echo $(patsubst %.d,"	(MODULE "%")",$(subst /,.,$(sort $(DOCLIST)))) | \
		sed 's/(/\x24(/g' | sed 's/ \t/\n\t/g' >> $(DOCDIR)/candydoc/modules.ddoc
	$(DC) -o- -D -Dd$(DOCDIR) $(DOCDIR)/candydoc/modules.ddoc $(DOCDIR)/candydoc/candy.ddoc $(DOCLIST)

~cleanunittest:
	rm -f unittest.o unittest

$(TARGET): $(OBJ)
	$(DC) -lib $(DCFLAGS) -of$@ $^

$(LIBDIR)/$(LIBNAME)/%.o: $(LIBNAME)/%.d
	$(DC) -c $(DCFLAGS) -of$@ $<

import/$(LIBNAME)/%.di: $(LIBNAME)/%.d
	$(DC) -c -o- -Hf$@ $<
