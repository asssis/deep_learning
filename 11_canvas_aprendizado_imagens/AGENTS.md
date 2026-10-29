# Regras deste projeto

- O reconhecimento de imagens usa uma CNN com filtros treináveis.
- Cada solicitação deve usar exatamente 6 versões modificadas por imagem: maior, menor, esquerda, direita, cima e baixo, por 35 épocas. Esta preferência substitui o pedido anterior de pelo menos 10 versões. A base inicial tem 5 exemplos por forma.
- Não aplicar rotação ou espelhamento às imagens de treinamento.
- Preservar exemplos ensinados e manter backup ao migrar o formato do modelo.
- A base inicial de formas só é treinada por solicitação. Não sobrescrever rótulos existentes. Zerar deve manter um backup restaurável, e abrir a página deve usar o modelo ativo salvo.
- Ao alterar aprendizado ou persistência, verificar `bundle exec rails test` e `bundle exec rails zeitwerk:check`.
