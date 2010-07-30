LIBNAME		=	orange
SRC			=	\
	_.d \
	serialization/Events.d \
	serialization/RegisterWrapper.d \
	serialization/Serializable.d \
	serialization/SerializationException.d \
	serialization/Serializer.d \
	serialization/_.d \
	serialization/archives/Archive.d \
	serialization/archives/ArchiveException.d \
	serialization/archives/XMLArchive.d \
	serialization/archives/_.d \
	util/CTFE.d \
	util/Reflection.d \
	util/Traits.d \
	util/Use.d \
	util/_.d \
	util/io.d \
	util/string.d \
	util/collection/Array.d \
	xml/PhobosXML.d \
	xml/XMLDocument.d \
	_.d

DC			=	dmd
DCFLAGS		=	-I/usr/include/d -I/usr/local/include/d


# Everything below this line should be fairly generic (with a few hard-coded things).

OBJ         =   $(addsuffix .o,$(addprefix $(LIBNAME)/,$(basename $(SRC))))
TARGET		=	lib/lib$(LIBNAME).a

all : $(TARGET)

install : $(TARGET)
	@echo Installing $(LIBNAME) . . .
	@cp $(TARGET) /usr/local/lib/lib$(LIBNAME).a
	@echo Installing $(LIBNAME) import files . . .
	@cp -r import/$(LIBNAME) /usr/local/include/d/$(LIBNAME)
	@echo done.

uninstall :
	@echo Uninstalling $(LIBNAME) import files . . .
	@rm -rf /usr/local/include/d/$(LIBNAME)
	@echo Uninstalling $(LIBNAME) . . .
	@rm -f /usr/local/lib/lib$(LIBNAME).a
	@echo done.

clean :
	@echo Cleaning $(LIBNAME) . . .
	@rm -rf import lib $(OBJ)
	@echo done.

$(TARGET) : $(OBJ)
	@echo Linking $@ . . .
	@$(DC) -lib $^ -of$@
	@echo done.

%.o : %.d
	@echo Compiling $< . . .
	@$(DC) -c $(DCFLAGS) $< -of$@ -Hfimport/$(basename $@).di
