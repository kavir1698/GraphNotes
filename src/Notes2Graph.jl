module Notes2Graph

using JuliaDB
using CSV
include("databases.jl")

greet() = print("Hello World!")

# parse bibtex files and add entries to the databases internal bibtex


if firsttime # create five tables to be filled
  bibfile = create_bibfile(savelocation)
  tables = initialize_databases()
  save_empty_databases(tables, savelocation)
else # load the tables from file
  tables = load_databases(savelocation)
end

# parse text files
# fill tables
# call information

end # module
