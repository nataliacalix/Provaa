const API = 'http://localhost:3000';

document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            btn.classList.add('active');
            document.getElementById(btn.dataset.tab).classList.add('active');
            
            if (btn.dataset.tab === 'lista') carregarProdutos();
            if (btn.dataset.tab === 'alertas') carregarAlertas();
            if (btn.dataset.tab === 'movimento') carregarSelect();
        });
    });

    carregarProdutos();
    carregarAlertas();
});

document.getElementById('formCadastro').onsubmit = async (e) => {
    e.preventDefault();
    const dados = {
        nome: e.target.nome.value,
        marca: e.target.marca.value,
        composicao: e.target.composicao.value,
        fragrancia: e.target.fragrancia.value,
        volume: e.target.volume.value,
        embalagem: e.target.embalagem.value,
        aplicacao: e.target.aplicacao.value,
        estoqueMinimo: Number(e.target.estoqueMinimo.value),
        estoqueAtual: Number(e.target.estoqueAtual.value)
    };

    await fetch(`${API}/produtos`, { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(dados) });
    alert('Produto cadastrado com sucesso!');
    e.target.reset();
    carregarProdutos();
    carregarAlertas();
};

async function carregarSelect() {
    const res = await fetch(`${API}/produtos`);
    const prods = await res.json();
    const select = document.getElementById('selectProduto');
    select.innerHTML = '<option value="">Selecione o produto</option>';
    prods.forEach(p => {
        select.innerHTML += `<option value="${p.id}">${p.nome} - ${p.marca} (Est: ${p.estoqueAtual})</option>`;
    });
}

async function movimentar() {
    const id = Number(document.getElementById('selectProduto').value);
    const qtd = Number(document.getElementById('qtd').value);
    const tipo = document.getElementById('tipo').value;
    const resp = document.getElementById('responsavel').value;

    if (!id || !qtd || !resp) return alert('Preencha tudo!');

    const endpoint = tipo === 'entrada' ? '/estoque/entrada' : '/estoque/saida';
    const res = await fetch(`${API}${endpoint}`, {
        method: 'PUT',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({ produtoId: id, quantidade: qtd, responsavel: resp })
    });

    const data = await res.json();
    alert(res.ok ? data.mensagem : data.erro);
    carregarProdutos();
    carregarAlertas();
}

async function carregarProdutos() {
    const res = await fetch(`${API}/produtos`);
    const prods = await res.json();
    const div = document.getElementById('listaProdutos');
    if (prods.length === 0) return div.innerHTML = '<p style="text-align:center;color:#666">Nenhum produto cadastrado.</p>';

    let html = `<table><tr><th>Nome</th><th>Marca</th><th>Volume</th><th>Estoque</th><th>Mínimo</th></tr>`;
    prods.forEach(p => {
        const classe = p.estoqueAtual <= p.estoqueMinimo ? 'baixo' : '';
        html += `<tr class="${classe}"><td>${p.nome}</td><td>${p.marca}</td><td>${p.volume}</td><td>${p.estoqueAtual}</td><td>${p.estoqueMinimo}</td></tr>`;
    });
    div.innerHTML = html + '</table>';
}

async function carregarAlertas() {
    const res = await fetch(`${API}/alertas`);
    const alertas = await res.json();
    const div = document.getElementById('listaAlertas');
    if (alertas.length === 0) {
        div.innerHTML = '<p style="color:#0f0;text-align:center">Todos os estoques estão OK!</p>';
    } else {
        div.innerHTML = alertas.map(a => `→ ${a.nome} (${a.marca}) → Estoque: ${a.estoqueAtual}/${a.estoqueMinimo}`).join('<br>');
    }
}