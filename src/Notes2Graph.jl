module Notes2Graph

import TextAnalysis: TokenDocument, stem!
import SQLite; sqlite = SQLite
import DataFrames: DataFrame
import Combinatorics: combinations
include("databases.jl")
include("parse.jl")

function main()
  # parse bibtex files and add entries to the databases internal bibtex


  # load/create databases
  if firsttime # create five tables to be filled
    bibfile = create_bibfile(savelocation)
    maindb = initialize_database();
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
