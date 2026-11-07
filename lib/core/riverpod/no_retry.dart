/// Disattiva i retry automatici di Riverpod 3: gli errori arrivano subito alla
/// UI, che offre il pulsante "Riprova".
Duration? noRetry(int retryCount, Object error) => null;
