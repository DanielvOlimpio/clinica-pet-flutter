const express = require('express');

const controller = require('../controllers/pets.controller');

const router = express.Router();

// POST /pets  -> cadastra um novo registro no PostgreSQL.
router.post('/', controller.cadastrar);

// GET  /pets  -> lista os registros armazenados no PostgreSQL.
router.get('/', controller.listar);

module.exports = router;
