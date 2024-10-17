const express = require('express')
const cors = require('cors')
const morgan = require('morgan')

//express
const app = express()
app.use(cors())
app.use(express.json())
app.use(morgan('combined'))

// route get version
app.get("/api", (req, res) => {
    res.send({ message: "API v.1.0.0" })
});

// app sur le port 3000
app.listen(3000, () => {
    console.log('app listening on port 3000!')
})