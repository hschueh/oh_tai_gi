var express = require('express'),
    bodyParser = require('body-parser'),
    methodOverride = require('method-override'),
    morgan = require('morgan'),
    restful = require('node-restful'),
    mongoose = restful.mongoose;
var app = express();

app.use(morgan('dev'));
app.use(bodyParser.urlencoded({'extended':'true'}));
app.use(bodyParser.json());
app.use(bodyParser.json({type:'application/vnd.api+json'}));
app.use(methodOverride());

mongoose.connect("mongodb://localhost:27017/ohtaigi", {useNewUrlParser: true, useUnifiedTopology: true });

var Resource = app.resource = restful.model('vocabulary_list', mongoose.Schema({
    _id: String,
    title: String,
    provider: String,
    cover: String,
    list: Array,
    createdAt: Date,
  }))
  .methods(['get']);

Resource.register(app, '/list');

app.listen(3000);
