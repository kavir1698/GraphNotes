module Notes2Graph

import TextAnalysis: TokenDocument, stem!
import SQLite; sqlite = SQLite
import DataFrames: DataFrame
import Combinatorics: combinations
include("databases.jl")
include("parse.jl")

export initialize_database, find_hashtags, word_stems, add_proposition!, add_t1!, add_t2!, add_t3!, add_t4!, add_t5!, add_t6!, table_length, update!

function main()
  # parse bibtex files and add entries to the databases internal bibtex


  # load/create databases
  if firsttime # create five tables to be filled
    bibfile = create_bibfile(savelocation)
    maindb = initialize_database(savelocation);
  else # load the tables from file
    maindb = load_database(savelocation)
  end

  # parse text files
  # get stems of words
  # fill tables
  # call information
  # edit entries in tables
end

end # module
