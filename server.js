const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

let produtos = [];
let proximoId = 1;

app.post('/produtos', (req, res) => {
    const produto = {
        id: proximoId++,
        ...req.body,
        estoqueAtual: Number(req.body.estoqueAtual) || 0,
        estoqueMinimo: Number(req.body.estoqueMinimo) || 10
    };
    produtos.push(produto);
    res.status(201).json({ mensagem: "Produto cadastrado!", produto });
});

app.get('/produtos', (req, res) => res.json(produtos));

app.put('/estoque/entrada', (req, res) => {
    const { produtoId, quantidade, responsavel } = req.body;
    const prod = produtos.find(p => p.id === produtoId);
    if (!prod) return res.status(404).json({ erro: "Produto não encontrado" });
    
    prod.estoqueAtual += Number(quantidade);
    res.json({ mensagem: "Entrada registrada!", estoqueAtual: prod.estoqueAtual });
});

app.put('/estoque/saida', (req, res) => {
    const { produtoId, quantidade, responsavel } = req.body;
    const prod = produtos.find(p => p.id === produtoId);
    if (!prod) return res.status(404).json({ erro: "Produto não encontrado" });
    if (prod.estoqueAtual < quantidade) return res.status(400).json({ erro: "Estoque insuficiente" });
    
    prod.estoqueAtual -= Number(quantidade);
    res.json({ mensagem: "Saída registrada!", estoqueAtual: prod.estoqueAtual });
});

app.get('/alertas', (req, res) => {
    const alertas = produtos
        .filter(p => p.estoqueAtual <= p.estoqueMinimo)
        .map(p => ({ id: p.id, nome: p.nome, marca: p.marca, estoqueAtual: p.estoqueAtual, estoqueMinimo: p.estoqueMinimo }));
    res.json(alertas);
});

app.listen(PORT, () => console.log(`Sistema rodando → http://localhost:${PORT}`));