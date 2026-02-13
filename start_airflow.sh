#!/bin/bash

# Script pour démarrer Airflow avec tous les composants
# ======================================================

# Définir AIRFLOW_HOME - CRITIQUE pour que Airflow trouve les bons DAGs
export AIRFLOW_HOME=/workspaces/airflow-snowflake-project

# Configuration Snowflake pour gérer les certificats / OCSP
# Désactive la validation OCSP du cache server (utile si problèmes cert S3)
export SNOWFLAKE_TEST_OCSP_MODE=FAIL_OPEN

# Activation de l'environnement virtuel
source /workspaces/airflow-snowflake-project/venv/bin/activate

echo "🛑 Arrêt des processus Airflow existants..."
# On utilise pgrep/pkill avec exclusion du script actuel
pkill -9 -f "airflow scheduler" 2>/dev/null
pkill -9 -f "airflow api-server" 2>/dev/null
pkill -9 -f "airflow triggerer" 2>/dev/null
# Libérer le port 8080 si occupé
lsof -ti :8080 | xargs -r kill -9 2>/dev/null
sleep 2

echo ""
echo "🧹 Nettoyage des tâches orphelines..."
# Nettoyer les tâches en état problématique pour éviter le crash HTTPStatusError
python -c "
from airflow.utils.session import create_session
from airflow.models import DagRun, TaskInstance

with create_session() as session:
    tis = session.query(TaskInstance).filter(
        TaskInstance.state.in_(['queued', 'running'])
    ).all()
    for ti in tis:
        session.delete(ti)
    
    runs = session.query(DagRun).filter(
        DagRun.state.in_(['queued', 'running'])
    ).all()
    for run in runs:
        session.delete(run)
    
    session.commit()
    print(f'   Nettoyé: {len(tis)} tâches, {len(runs)} runs')
" 2>/dev/null || echo "   Pas de nettoyage nécessaire"

echo ""
echo "🚀 Démarrage d'Airflow..."
echo "   AIRFLOW_HOME: $AIRFLOW_HOME"
echo "   DAGs folder: $AIRFLOW_HOME/dags"
echo ""

# Lancer le scheduler en arrière-plan
echo "📅 Démarrage du Scheduler..."
nohup airflow scheduler >> /tmp/airflow-scheduler.log 2>&1 &
SCHEDULER_PID=$!
echo "   Scheduler PID: $SCHEDULER_PID"

# Lancer le dag-processor (Airflow 3) pour parser les DAGs
echo "🧠 Démarrage du DAG Processor..."
nohup airflow dag-processor >> /tmp/airflow-dag-processor.log 2>&1 &
DAG_PROCESSOR_PID=$!
echo "   DAG Processor PID: $DAG_PROCESSOR_PID"

# Attendre que le scheduler soit prêt
sleep 5

# Lancer l'API server (remplace webserver dans Airflow 3)
echo "🌐 Démarrage de l'API Server (port 8080)..."
nohup airflow api-server --port 8080 >> /tmp/airflow-api-server.log 2>&1 &
API_PID=$!
echo "   API Server PID: $API_PID"

sleep 3

# Lancer le triggerer
echo "⚡ Démarrage du Triggerer..."
nohup airflow triggerer >> /tmp/airflow-triggerer.log 2>&1 &
TRIGGERER_PID=$!
echo "   Triggerer PID: $TRIGGERER_PID"

echo ""
echo "✅ Airflow démarré!"
echo "   Interface web: http://localhost:8080"
echo "   Login: admin / (mot de passe dans standalone_admin_password.txt)"
echo ""
echo "   Logs:"
echo "     - Scheduler: /tmp/airflow-scheduler.log"
echo "     - API Server: /tmp/airflow-api-server.log"
echo "     - Triggerer: /tmp/airflow-triggerer.log"
echo ""
echo "Pour arrêter: pkill -f 'airflow scheduler|airflow api-server|airflow triggerer'"
echo ""
