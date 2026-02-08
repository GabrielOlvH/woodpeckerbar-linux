import type { Pipeline, Repo } from "./types"

function formatDuration(startSecs: number, finishSecs: number): number {
  if (!startSecs || !finishSecs) return 0
  return finishSecs - startSecs
}

function parsePipeline(raw: any): Pipeline | null {
  if (!raw) return null
  return {
    id: raw.id,
    number: raw.number,
    status: raw.status,
    event: raw.event,
    branch: raw.branch || "",
    message: (raw.message || "").split("\n")[0],
    author: raw.author || raw.sender || "",
    commit: (raw.commit || "").slice(0, 7),
    created: raw.created || 0,
    started: raw.started || 0,
    finished: raw.finished || 0,
    duration: formatDuration(raw.started, raw.finished),
  }
}

export async function fetchRepos(baseUrl: string, token: string): Promise<Repo[]> {
  const res = await fetch(`${baseUrl}/api/user/repos`, {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  const raw = (await res.json()) as any[]

  return raw
    .filter((r: any) => r.active)
    .map((r: any) => ({
      id: r.id,
      name: r.name,
      full_name: r.full_name,
      active: r.active,
      last_pipeline: parsePipeline(r.last_pipeline),
    }))
    .sort((a, b) => {
      const aTime = a.last_pipeline?.created || 0
      const bTime = b.last_pipeline?.created || 0
      return bTime - aTime
    })
}

export async function fetchRecentPipelines(baseUrl: string, token: string, repoId: number, count = 5): Promise<Pipeline[]> {
  const res = await fetch(`${baseUrl}/api/repos/${repoId}/pipelines?per_page=${count}`, {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!res.ok) return []
  const raw = (await res.json()) as any[]
  return raw.map(parsePipeline).filter((p): p is Pipeline => p !== null)
}
