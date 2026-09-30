# Helpia

Ajuda no terminal Linux. Você faz uma pergunta e o Helpia utiliza Ia para devolver o comando, com uma explicação curta dos argumentos.

## Instalação

```bash
curl -fsSL https://raw.githubusercontent.com/rafaelmarquesmatos/helpia/main/install.sh | bash
```

O instalador confere os requisitos (`bash`, `curl`, `jq` e `git`), baixa o Helpia e cria `~/.local/bin/helpia`. 

## Uso

```bash
helpia "como crio uma pasta"         # realiza a pergunta
helpia --provider                    # mostra o provedor atual
helpia --provider openrouter         # troca o provedor
helpia --model                       # mostra o modelo atual
helpia --model inception/mercury-2.5 # troca o modelo
helpia --help                        # lista os comandos
helpia --update                      # atualiza o helpia
```

## Provedores

OpenRouter: [https://openrouter.ai](https://openrouter.ai)

## Licença

MIT. Veja [LICENSE](LICENSE).