#!/usr/bin/env python3
# Export real datasets to frontend static JSON files

import os
import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATHS = [ROOT / 'neta_data.sqlite', ROOT / 'data' / 'neta_data.sqlite', ROOT / '..' / 'neta_data.sqlite']
OUT_DIR = ROOT / 'frontend' / 'public' / 'data'


def find_db():
    for p in DB_PATHS:
        if p.exists():
            return p
    raise FileNotFoundError('neta_data.sqlite not found in expected locations')


def get_connection(db_path: Path):
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    return conn


def fetch_real_datasets(conn):
    # Only datasets that actually have gene_expression rows
    query = """
    SELECT d.*,
           (SELECT COUNT(1) FROM gene_expression ge WHERE ge.dataset_id = d.id) AS expr_count
    FROM datasets d
    WHERE EXISTS (SELECT 1 FROM gene_expression ge WHERE ge.dataset_id = d.id)
      AND (d.status IS NULL OR d.status = 'active')
    ORDER BY d.priority ASC, d.id ASC
    """
    return [dict(row) for row in conn.execute(query).fetchall()]


def fetch_stats(conn):
    # Global stats limited to real-expression datasets
    total_datasets = conn.execute("""
        SELECT COUNT(1) FROM datasets d WHERE EXISTS(SELECT 1 FROM gene_expression ge WHERE ge.dataset_id = d.id)
    """).fetchone()[0]
    total_samples = conn.execute("SELECT COUNT(1) FROM samples").fetchone()[0]
    total_genes = conn.execute("SELECT COUNT(1) FROM genes").fetchone()[0]
    total_expressions = conn.execute("SELECT COUNT(1) FROM gene_expression").fetchone()[0]

    tissue_stats = [
        {"name": r[0], "count": r[1]}
        for r in conn.execute(
            """
            SELECT d.tissue_type, COUNT(1)
            FROM datasets d
            WHERE EXISTS(SELECT 1 FROM gene_expression ge WHERE ge.dataset_id = d.id)
            GROUP BY d.tissue_type
            ORDER BY COUNT(1) DESC
            """
        ).fetchall()
    ]

    tumor_stats = [
        {"name": r[0], "count": r[1]}
        for r in conn.execute(
            """
            SELECT d.tumor_type, COUNT(1)
            FROM datasets d
            WHERE EXISTS(SELECT 1 FROM gene_expression ge WHERE ge.dataset_id = d.id)
            GROUP BY d.tumor_type
            ORDER BY COUNT(1) DESC
            """
        ).fetchall()
    ]

    return {
        "total_datasets": total_datasets,
        "total_samples": total_samples,
        "total_genes": total_genes,
        "total_expressions": total_expressions,
        "tissue_types": tissue_stats,
        "tumor_types": tumor_stats,
    }


def main():
    db_path = find_db()
    conn = get_connection(db_path)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    datasets = fetch_real_datasets(conn)

    # Trim fields and keep only necessary
    datasets_min = []
    for d in datasets:
        datasets_min.append({
            'id': d['id'],
            'geo_id': d['geo_id'],
            'title': d.get('title'),
            'description': d.get('description'),
            'tissue_type': d.get('tissue_type'),
            'tumor_type': d.get('tumor_type'),
            'platform': d.get('platform'),
            'n_samples': d.get('n_samples'),
            'n_genes': d.get('n_genes'),
            'publication_year': d.get('publication_year'),
            'data_source': d.get('data_source'),
            'priority': d.get('priority') if 'priority' in d else None,
        })

    stats = fetch_stats(conn)

    with open(OUT_DIR / 'datasets.json', 'w') as f:
        json.dump({
            'datasets': datasets_min,
            'total': len(datasets_min),
            'pages': 1,
            'current_page': 1
        }, f, indent=2, ensure_ascii=False)

    with open(OUT_DIR / 'stats.json', 'w') as f:
        json.dump(stats, f, indent=2, ensure_ascii=False)

    print('Exported:', OUT_DIR / 'datasets.json')
    print('Exported:', OUT_DIR / 'stats.json')


if __name__ == '__main__':
    main()
