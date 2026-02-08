import { fetchRepos, fetchRecentPipelines } from "./api"
import type { WoodpeckerBarOutput } from "./types"

function parseArgs() {
  const args = process.argv.slice(2)
  return {
    url: args.find((_, i, a) => a[i - 1] === "--url") || "https://ci.kaia.systems",
    token: args.find((_, i, a) => a[i - 1] === "--token") || "",
    pipelines: args.includes("--pipelines"),
    repoId: Number(args.find((_, i, a) => a[i - 1] === "--repo") || 0),
  }
}

async function main() {
  const { url, token, pipelines, repoId } = parseArgs()

  if (!token) {
    console.log(JSON.stringify({ error: "no_token", repos: [], running: 0, failing: 0, timestamp: new Date().toISOString() }))
    return
  }

  if (pipelines && repoId) {
    const result = await fetchRecentPipelines(url, token, repoId)
    console.log(JSON.stringify({ pipelines: result, timestamp: new Date().toISOString() }))
    return
  }

  const repos = await fetchRepos(url, token)
  const running = repos.filter((r) => r.last_pipeline?.status === "running" || r.last_pipeline?.status === "pending").length
  const failing = repos.filter((r) => r.last_pipeline?.status === "failure" || r.last_pipeline?.status === "error").length

  const output: WoodpeckerBarOutput = {
    repos,
    running,
    failing,
    timestamp: new Date().toISOString(),
  }

  console.log(JSON.stringify(output))
}

main()
