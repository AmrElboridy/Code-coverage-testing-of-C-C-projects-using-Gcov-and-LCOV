
#include "unity_fixture.h"

/* define test group */
TEST_GROUP(amr);

/* test setup and tear down. Run prior / after each test */
TEST_SETUP(amr)
{
}

TEST_TEAR_DOWN(amr)
{
}

/* implement tests here using the TEST() macro.
 * Use the following comment header for specifying the test. The header will
 * automatically get extracted and added to the documentation output (pdf).
 *
 * The following rules apply:
 * - The first line MUST contains the ID: line. ID must be on the opening
 *   comment line. The ID value MUST be unique for the test.
 *   However, the final ID is created as combination of the ID value and the
 *   test name, so numbers don't need to be unique between different tests.
 * - Each keyword MUST be followed by a colon and at least one whitespace
 *   character.
 * - ID: value is numeric, all other values are strings.
 * - TAGS: is a comma separated list with words. They will be split up during
 *   processing to be used for variant matching later.
 * - All keywords are parsed up to the end of the line only.
 * - The detailed description doesn't have a keyword and can be multiline. This
 *   is the only entry that can be multiline.
 * - The comment MUST be followed by the TEST() macro on the next line.
 */

/* ID: 0001
 * STATUS: draft
 * VERSION: 1
 * TAGS: Audi
 * SHORTDESC: Short (one line) description of the test.
 *
 * A more detailed description can follow after the last element. It MUST be
 * separated from the previous element using a blank line. All lines may start
 * with a leading * for improved readability of the comment.
 */
/* TEST(amr, NameOfTest)
{
    do_something();
    TEST_ASSERT_EQUAL(expected, actual);
    TEST_ASSERT_TRUE(condition);
    TEST_ASSERT_FALSE(condition);
    TEST_ASSERT_INT_WITHIN(delta, expected, actual);
    see_unity_docs_for_further_test_macros();
}
*/

/* test group runner. Add each test case here */
TEST_GROUP_RUNNER(amr)
{
    /* RUN_TEST_CASE(amr, NameOfTest); */
}

/* test group. No need to change this. */
void RunAllTests(void)
{
    RUN_TEST_GROUP(amr)
}

