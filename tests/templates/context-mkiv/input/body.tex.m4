\begingroup
% Load the test-specific setup.
\input TEST_SETUP_FILENAME\relax
% Prevent the folding of characters into a single space token in logs.
\catcode"09=12%  Tabs (U+0009)
\catcode"20=12%  Spaces (U+0020)
% Disable active characters of the TeX engine.
\catcode"7E=12%  Tildes (U+007E)
% Perform the test.
\def\markdownRendererDocumentEnd{}
\inputmarkdown{TEST_INPUT_FILENAME}%
\TYPE{Here is some extra output}
\TYPE{documentEnd}
\endgroup
