
function create_bibfile(savelocation)
  bibfile = joinpath(savelocation, "internalbibtex.bib")
  if isfile(bibfile)
    return bibfile
  end
  open(bibfile, "w")
  return bibfile
end

function load_database(savelocation)
  maindb = sqlite.DB(joinpath(savelocation, "notes2graphdb"))
  return maindb
end


## SQLite functions

function initialize_database()
  maindb = sqlite.DB(joinpath(savelocation, "notes2graphdb"))
  # t1 is a table that keeps a list of all nodes, i.e. concepts
  stmt = "CREATE TABLE t1 (nodeid INTEGER NOT NULL UNIQUE, nodename TEXT NOT NULL UNIQUE, PRIMARY KEY (nodeid, nodename))"
  j = sqlite.Stmt(maindb, stmt)
  sqlite.execute!(j)

  # t2 is a table that keeps a list of descriptions and references for each node or relation
  stmt = "CREATE TABLE t2 (descrid INTEGER NOT NULL UNIQUE PRIMARY KEY, descr TEXT NOT NULL UNIQUE, ref TEXT)"
  j = sqlite.Stmt(maindb, stmt)
  sqlite.execute!(j)

  # t3 is a table that keeps a list of associations between node ids and description ids
  stmt = "CREATE TABLE t3 (nodeid INTEGER NOT NULL, descrid INTEGER NOT NULL, PRIMARY KEY (nodeid, descrid))"
  j = sqlite.Stmt(maindb, stmt)
  sqlite.execute!(j)

  # t4 is a table that keeps a list of associations between related node ids
  stmt = "CREATE TABLE t4 (nodeid INTEGER NOT NULL, relatedid INTEGER NOT NULL, PRIMARY KEY (nodeid, relatedid))"
  j = sqlite.Stmt(maindb, stmt)
  sqlite.execute!(j)

  # t5 is a table that keeps a list of hierarchies between node ids.
  stmt = "CREATE TABLE t5 (nodeid INTEGER NOT NULL, upid INTEGER NOT NULL, PRIMARY KEY (nodeid, upid))"
  j = sqlite.Stmt(maindb, stmt)
  sqlite.execute!(j)

  # t6 is a table that keeps a list of all the derived words for each stem in the table 1 as `nodename`
  stmt = "CREATE TABLE t6 (nodeid INTEGER NOT NULL, derivatives TEXT NOT NULL, PRIMARY KEY (nodeid, derivatives))"
  j = sqlite.Stmt(maindb, stmt)
  sqlite.execute!(j)

  return maindb
end