const petsService = require('../services/pets.service');

// Valores aceitos pelo PostgreSQL NUMERIC: converte "150,50" -> 150.50.
function normalizarValor(valorBruto) {
  if (typeof valorBruto === 'number') {
    return valorBruto;
  }
  return Number(String(valorBruto ?? '').trim().replace(',', '.'));
}

// POST /pets — cadastra um novo atendimento no PostgreSQL.
// Comportamento idempotente: se o id_local ja existe (re-envio de um registro
// pendente apos falha de comunicacao), devolve o registro JA EXISTENTE
// em vez de criar uma duplicidade.
async function cadastrar(req, res, next) {
  try {
    const { idLocal, atendimentoId, nome, especie, valor } = req.body || {};

    // Validacao dos campos obrigatorios.
    const problemas = [];
    if (typeof idLocal !== 'string' || !idLocal.trim()) {
      problemas.push('idLocal e obrigatorio');
    }
    const atendimentoIdNum = Number(atendimentoId);
    if (!Number.isInteger(atendimentoIdNum) || atendimentoIdNum <= 0) {
      problemas.push('atendimentoId deve ser um numero inteiro maior que zero');
    }
    if (typeof nome !== 'string' || !nome.trim()) {
      problemas.push('nome e obrigatorio');
    }
    if (typeof especie !== 'string' || !especie.trim()) {
      problemas.push('especie e obrigatoria');
    }
    const valorNum = normalizarValor(valor);
    if (!Number.isFinite(valorNum) || valorNum <= 0) {
      problemas.push('valor deve ser um numero maior que zero');
    }

    if (problemas.length > 0) {
      return res.status(400).json({ erro: problemas.join('; ') });
    }

    const registro = {
      idLocal: idLocal.trim(),
      atendimentoId: atendimentoIdNum,
      nome: nome.trim(),
      especie: especie.trim(),
      valor: valorNum,
    };

    // Idempotencia: registro ja gravado em envio anterior?
    const existente = await petsService.buscarPorIdLocal(registro.idLocal);
    if (existente) {
      return res.status(200).json(existente);
    }

    const criado = await petsService.inserir(registro);
    return res.status(201).json(criado);
  } catch (erro) {
    // Erro e repassado ao middleware central de erros: o servidor NAO encerra.
    return next(erro);
  }
}

// GET /pets — lista os atendimentos armazenados no PostgreSQL.
async function listar(_req, res, next) {
  try {
    const registros = await petsService.listarTodos();
    return res.status(200).json(registros);
  } catch (erro) {
    return next(erro);
  }
}

module.exports = { cadastrar, listar };
