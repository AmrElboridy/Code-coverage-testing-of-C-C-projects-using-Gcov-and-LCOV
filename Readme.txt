
Unit Test Howto
===============
This folder contains unit tests. Each test is in a separate folder using the
prefix "test_". The tests use the "unity" test framework.

Generate a new test
-------------------
The Python script ``createtest.py`` will ask for a test name and create a
folder with a test template. The created template will compile but doesn't
contain any tests and needs to get adjusted:
- in ``Makefile`` edit the variables ``INCLUDES`` and ``SOURCES`` and add the
  required files and folders.
- in the generated source file create new tests using the ``TEST`` macro. Add
  new tests to the ``TEST_GROUP_RUNNER``.

A detailed documentation about the unit test framework "unity" can be found in
the unity folder.

Running tests
-------------
The Python script ``runtests.py`` will run all tests found and report the
result in a short summary. It will also generate a ``testresult.xml`` used by
Jenkins to display test results.

Tests are build using the MinGW toolchain. The Python script will automatically
download and install the toolchain if necessary.

Each test can be build and executed individually by passing the test name as
argument to ``runtests.py``. Each test executable can also be executed
individually. When run individually the argument ``-v`` makes the test run
output more verbose.

Each test can also be built individually without the help of ``runtests.py`` by
invoking ``mingw32-make`` in the tests folder and running the resulting
executable afterwards. This requires the MinGW toolchain to be available in the
environment PATH. See the unity documentation for details.

Using Visual Studio
-------------------
The Python script ``runtests.py`` creates a Visual Studio project file (VS2008)
when running tests. You can use the generated project file to update / debug
the tests when necessary. It's important to keep a couple of things in mind
when doing so:
- The project file is generated and will get updated on the next invocation of
  ``runtests.py``. To add / remove files, change compiler flags etc. you need
  to edit the ``Makefile``.
- MSVC only supports C89. If a test uses C99 features it won't work with MSVC.
- Only defines and include folders passed to the compiler are added to the
  project file. All other compiler options are ignored. The generated project
  file uses fixed values for those (like warning level).

WARNING: when using MSVC all source files from production code are first copied
to a temporary folder (``_build``). This is necessary since MSVC always
searches the folder the source file is in for headers, and there is no way to
disable this. However, when overwriting headers that are available in the same
production code folder MSVC would pick the wrong file, so copying it around
first is necessary. This means that production code files shown in the MSVC
project file are copies. Editing those files will not have the desired effect!
