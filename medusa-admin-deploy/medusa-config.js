module.exports = {
  projectConfig: {
    database_url: "postgres://localhost/medusa",
    database_type: "postgres",
    http: {
      jwtSecret: "supersecret",
      cookieSecret: "supersecret"
    }
  },
  admin: {
    disable: false,
    backendUrl: process.env.MEDUSA_BACKEND_URL || "http://localhost:9000"
  }
}
