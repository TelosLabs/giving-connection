$max_mind_db = MaxMindDB.new("#{Rails.root}/app/assets/GeoLite2-City.mmdb", MaxMindDB::LOW_MEMORY_FILE_READER)

# ret = db.lookup('74.125.225.224')