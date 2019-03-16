module Notes2Graph

import TextAnalysis: TokenDocument, stem!
import SQLite; sqlite = SQLite
import DataFrames: DataFrame
import Combinatorics: combinations
include("databases.jl")
include("parse.jl")
include("BibTex.jl")

export initialize_database, find_hashtags, word_stems, add_proposition!, add_t1!, add_t2!, add_t3!, add_t4!, add_t5!, add_t6!, table_length, update!, DataFrame, sqlite, load_database, find_nodeid, related_concepts, find_descrid, descriptions, derivatives, relationid, relation_descr

function main(savelocation)
  
  # load/create databases
  dbfile = joinpath(savelocation, "notes2graphdb.sqlite")
  bibfile = joinpath(savelocation, "internalbibtex.bib")
  if !isfile(dbfile) # create five tables to be filled
    bibfile = create_bibfile(savelocation)
    maindb = initialize_database(savelocation);
  else # load the tables from file
    maindb = load_database(savelocation)
  end
  
  # parse text files
  # parse bibtex files and add entries to the databases internal bibtex
  # get stems of words
  # fill tables
  # call information
  # edit entries in tables
  # pretty print results
end

end # module
