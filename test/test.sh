#!/usr/local/bin/ic-repl --replica local
import DAOContract = "u6s2n-gx777-77774-qaaba-cai";

call DAOContract.getDefaultTokens();
let result = _;
print result;
assert result.name == "Test DAO";







