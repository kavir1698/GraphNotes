module Notes2Graph

import ArgParse; ap = ArgParse
import TextAnalysis: TokenDocument, stem!
import SQLite; sqlite = SQLite
import DataFrames: DataFrame
import Combinatorics: combinations
include("databases.jl")
include("parse.jl")
include("BibTeX.jl")

export initialize_database, find_hashtags, word_stems, add_proposition!, add_t1!, add_t2!, add_t3!, add_t4!, add_t5!, add_t6!, table_length, update!, DataFrame, sqlite, load_database, find_nodeid, related_concepts, find_descrid, descriptions, derivatives, relationid, relation_descr

main()

end # module
