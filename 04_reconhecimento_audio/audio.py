"""Converte voz em uma lista fixa de características, fora da rede."""

import json
import sys
import wave

import numpy as np

QUANTIDADE_ENTRADAS = 16 * 16


def carregar_audio(caminho):
    with wave.open(str(caminho), "rb") as arquivo:
        if arquivo.getsampwidth() != 2 or arquivo.getcomptype() != "NONE":
            raise ValueError("Use WAV PCM de 16 bits, como os arquivos de gravar.py.")
        taxa = arquivo.getframerate()
        canais = arquivo.getnchannels()
        dados = np.frombuffer(arquivo.readframes(arquivo.getnframes()), dtype="<i2")
    if dados.size == 0:
        raise ValueError("O áudio está vazio.")
    sinal = dados.astype(np.float64).reshape(-1, canais).mean(axis=1) / 32768
    if taxa < 8000:
        raise ValueError("Use uma taxa de amostragem de pelo menos 8000 Hz.")
    # Padroniza a taxa, remove silêncio nas pontas e normaliza o volume.
    sinal = np.interp(np.arange(0, len(sinal), taxa / 16000), np.arange(len(sinal)), sinal)
    pico = np.max(np.abs(sinal))
    if pico < 0.005:
        raise ValueError("Áudio silencioso ou volume muito baixo. Grave novamente.")
    ativos = np.flatnonzero(np.abs(sinal) > pico * 0.08)
    sinal = sinal[max(0, ativos[0] - 800):min(len(sinal), ativos[-1] + 801)] / pico
    sinal = np.pad(sinal, (0, max(0, 400 - len(sinal))))
    # Espectro em janelas de 25 ms; 16 faixas e 16 posições no tempo.
    janelas = np.lib.stride_tricks.sliding_window_view(sinal, 400)[::160]
    espectro = np.abs(np.fft.rfft(janelas * np.hanning(400), axis=1)) ** 2
    frequencias = np.fft.rfftfreq(400, 1 / 16000)
    limites = np.geomspace(80, 8000, 17)
    faixas = np.stack([
        np.log1p(espectro[:, (frequencias >= inicio) & (frequencias < fim)].mean(axis=1))
        for inicio, fim in zip(limites[:-1], limites[1:])
    ])
    tempos = np.linspace(0, faixas.shape[1] - 1, 16)
    entrada = np.stack([np.interp(tempos, np.arange(len(faixa)), faixa) for faixa in faixas])
    entrada /= max(float(entrada.max()), 1e-12)
    return entrada.ravel().tolist()


if __name__ == "__main__":
    print(json.dumps(carregar_audio(sys.argv[1])))
