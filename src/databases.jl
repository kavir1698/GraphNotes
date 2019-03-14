
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

function initialize_database()
  maindb = sqlite.DB(joinpath(savelocation, "notes2graphdb"))
  # t1 is a table that keeps a list of all nodes, i.e. concepts
  stmt = "CREATE TABLE IF NOT EXISTS t1 (nodeid INTEGER NOT NULL UNIQUE, nodename TEXT NOT NULL UNIQUE, PRIMARY KEY (nodeid, nodename))"
  sqlite.query(maindb, stmt)
  # j = sqlite.Stmt(maindb, stmt)
  # sqlite.execute!(j)

  # t2 is a table that keeps a list of descriptions and references for each node or relation
  stmt = "CREATE TABLE IF NOT EXISTS t2 (descrid INTEGER NOT NULL UNIQUE PRIMARY KEY, descr TEXT NOT NULL UNIQUE, ref TEXT)"
  sqlite.query(maindb, stmt)
  # j = sqlite.Stmt(maindb, stmt)
  # sqlite.execute!(j)

  # t3 is a table that keeps a list of associations between node ids and description ids
  stmt = "CREATE TABLE IF NOT EXISTS t3 (nodeid INTEGER NOT NULL, descrid INTEGER NOT NULL, PRIMARY KEY (nodeid, descrid))"
  sqlite.query(maindb, stmt)
  # j = sqlite.Stmt(maindb, stmt)
  # sqlite.execute!(j)

  # t4 is a table that keeps a list of associations between related node ids
  stmt = "CREATE TABLE IF NOT EXISTS t4 (nodeid INTEGER NOT NULL, relatedid INTEGER NOT NULL, PRIMARY KEY (nodeid, relatedid))"
  sqlite.query(maindb, stmt)
  # j = sqlite.Stmt(maindb, stmt)
  # sqlite.execute!(j)

  # t5 is a table that keeps a list of hierarchies between node ids.
  stmt = "CREATE TABLE IF NOT EXISTS t5 (nodeid INTEGER NOT NULL, upid INTEGER NOT NULL, PRIMARY KEY (nodeid, upid))"
  sqlite.query(maindb, stmt)
  # j = sqlite.Stmt(maindb, stmt)
  # sqlite.execute!(j)

  # t6 is a table that keeps a list of all the derived words for each stem in the table 1 as `nodename`
  stmt = "CREATE TABLE IF NOT EXISTS t6 (nodeid INTEGER NOT NULL, derivative TEXT NOT NULL, PRIMARY KEY (nodeid, derivative))"
  sqlite.query(maindb, stmt)
  # j = sqlite.Stmt(maindb, stmt)
  # sqlite.execute!(j)

  return maindb
end

function add_t1!(maindb::SQLite.DB, nodename)
  nodeid = table_length(maindb, "t1") + 1
  stmt = "INSERT OR IGNORE INTO t1 (nodeid, nodename) VALUES ($nodeid, '$nodename')"
  sqlite.query(maindb, stmt)
  return nodeid
end

function add_t2!(maindb::SQLite.DB, descr, ref)
  stmt = "INSERT OR IGNORE INTO t2 (descr, ref) VALUES ('$descr', '$ref')"
  sqlite.query(maindb, stmt)
  descrid = DataFrame(sqlite.query(maindb, "SELECT MAX(1) FROM t2"))[1,1]
  return descrid
end

function add_t3!(maindb::SQLite.DB, nodeid::Integer, descrid::Integer)
  stmt = "INSERT OR IGNORE INTO t3 (nodeid, descrid) VALUES ($nodeid, $descrid)"
  sqlite.query(maindb, stmt)
end

function add_t4!(maindb::SQLite.DB, nodeid::Integer, relatedid::Integer)
  stmt = "INSERT OR IGNORE INTO t4 (nodeid, relatedid) VALUES ($nodeid, $relatedid)"
  sqlite.query(maindb, stmt)
end

function add_t5!(maindb::SQLite.DB, nodeid::Integer, upid::Integer)
  stmt = "INSERT OR IGNORE INTO t5 (nodeid, upid) VALUES ($nodeid, $upid)"
  sqlite.query(maindb, stmt)
end

function add_t6!(maindb::SQLite.DB, nodeid::Integer, derivative)
  stmt = "INSERT OR IGNORE INTO t6 (nodeid, derivative) VALUES ($nodeid, '$derivative')"
  sqlite.query(maindb, stmt)
end

"populate all tables"
function add_proposition!(maindb::SQLite.DB, proposition, nodes, stems, refs)
  nnodes = length(nodes)
  all_nodeids = Array{Integer}(undef, nnodes)
  for nn in 1:nnodes
    nodeid = add_t1!(maindb, stems[nn])
    all_nodeids[nn] = nodeid
    if stems[nn] != nodes[nn]
      add_t6!(maindb, nodeid, nodes[nn])
    end
    descrid = add_t2!(maindb, proposition, refs)
    add_t3!(maindb, nodeid, descrid)
  end
  if length(all_nodeids) > 1
    combs = combinations(all_nodeids, 2)
    for comb in combs
      add_t4!(maindb, comb[1], comb[2])
    end
  end
end

# TODO update t5

function table_length(maindb::SQLite.DB, tablename)
  # nrows = sqlite.execute!(maindb, "SELECT Count(1) FROM $tablename")
  nrows = DataFrame(sqlite.query(maindb, "SELECT Count(1) FROM $tablename"))[1,1]
  return nrows
end