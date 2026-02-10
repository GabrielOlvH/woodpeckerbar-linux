export interface Step {
  name: string
  state: string
  type: string
}

export interface Pipeline {
  id: number
  number: number
  status: string
  event: string
  branch: string
  message: string
  author: string
  commit: string
  created: number
  started: number
  finished: number
  duration: number
  steps: Step[]
}

export interface Repo {
  id: number
  name: string
  full_name: string
  active: boolean
  last_pipeline: Pipeline | null
  link: string
}

export interface WoodpeckerBarOutput {
  repos: Repo[]
  running: number
  failing: number
  timestamp: string
}
