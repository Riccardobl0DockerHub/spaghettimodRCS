local auth = require"std.auth"
cs.adduser(os.getenv("ADMIN"), os.getenv("AUTH_DOMAIN"), os.getenv("ADMIN_KEY"), "a")
table.insert(auth.preauths,  os.getenv("AUTH_DOMAIN"))
