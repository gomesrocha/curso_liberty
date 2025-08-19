import re
from opensearchpy import OpenSearch
from opensearchpy.helpers import bulk

# Configuração da conexão com OpenSearch (sem segurança, para setup local)
client = OpenSearch(
    hosts=[{'host': 'localhost', 'port': 9200}],
    http_compress=True,
    use_ssl=False,  # Sem SSL para setup local sem segurança
    verify_certs=False
)

# Caminho para o arquivo de log do Open Liberty (ajuste conforme necessário)
log_file_path = './wlp/usr/servers/meuServidor/logs/messages_25.08.19_15.35.10.0.log'  # Exemplo: substitua pelo caminho real

# Regex simples para parsear logs do Open Liberty (formato: [timestamp] thread level message)
log_pattern = re.compile(r'\[(.*?)\]\s+(.*?)\s+([A-Z]+)\s+(.*)')

# Função para ler e preparar logs para indexação
def prepare_logs():
    actions = []
    with open(log_file_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            match = log_pattern.match(line)
            if match:
                timestamp, thread, level, message = match.groups()
                doc = {
                    'timestamp': timestamp,
                    'thread': thread,
                    'level': level,
                    'message': message
                }
            else:
                # Se não parsear, indexa como mensagem crua
                doc = {
                    'timestamp': 'unknown',
                    'thread': 'unknown',
                    'level': 'unknown',
                    'message': line
                }
            action = {
                '_index': 'openliberty-logs',
                '_source': doc
            }
            actions.append(action)
    return actions

# Indexação em bulk
actions = prepare_logs()
if actions:
    success, failed = bulk(client, actions)
    print(f'Successfully indexed {success} logs. Failed: {failed}')
else:
    print('No logs to index.')

# Crie o índice se não existir (opcional, mas recomendado)
if not client.indices.exists(index='openliberty-logs'):
    client.indices.create(index='openliberty-logs')
    print('Index created.')