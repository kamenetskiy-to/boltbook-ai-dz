package matching

import (
	"fmt"
	"math"
	"sort"
	"strings"
	"time"

	"boltbook-ai-dz/internal/core"
	"boltbook-ai-dz/internal/domain"
)

func Rank(task domain.Task, executors []domain.ExecutorPortfolio) domain.MatchResult {
	candidates := make([]domain.MatchCandidate, 0, len(executors))
	for _, executor := range executors {
		if executor.AvailabilityState != domain.AvailabilityActive {
			continue
		}
		score, reasons, risks := scoreExecutor(task, executor)
		candidates = append(candidates, domain.MatchCandidate{
			ExecutorID: executor.ExecutorID,
			Score:      score,
			FitSummary: fitSummary(task, executor, score),
			FitReasons: reasons,
			Risks:      risks,
		})
	}

	sort.SliceStable(candidates, func(i, j int) bool {
		if candidates[i].Score == candidates[j].Score {
			return candidates[i].ExecutorID < candidates[j].ExecutorID
		}
		return candidates[i].Score > candidates[j].Score
	})

	if len(candidates) > 5 {
		candidates = candidates[:5]
	}
	for i := range candidates {
		candidates[i].Rank = i + 1
	}

	selectionReason := "No active executor was available for this task."
	if len(candidates) > 0 {
		selectionReason = fmt.Sprintf("%s is the strongest available executor for the requested task.", humanizeExecutorID(candidates[0].ExecutorID))
	}

	return domain.MatchResult{
		ResultID:        core.NextID("match"),
		TaskID:          task.TaskID,
		GeneratedAt:     time.Now().UTC(),
		Candidates:      candidates,
		SelectionReason: selectionReason,
	}
}

func scoreExecutor(task domain.Task, executor domain.ExecutorPortfolio) (float64, []string, []string) {
	taskTags := normalize(task.TaskTags)
	executorTags := normalize(executor.CapabilityTags)
	overlap := intersectCount(taskTags, executorTags)

	score := 0.15
	reasons := []string{}
	risks := []string{}

	if len(taskTags) > 0 {
		tagScore := float64(overlap) / float64(len(taskTags))
		score += tagScore * 0.55
		if overlap > 0 {
			reasons = append(reasons, fmt.Sprintf("Capability tags overlap with %s.", strings.Join(commonSlice(taskTags, executorTags), ", ")))
		}
	}

	if executor.TrustSignals.OperatorCurated {
		score += 0.15
		reasons = append(reasons, "Operator-curated portfolio reduces discovery uncertainty.")
	} else {
		risks = append(risks, "Portfolio relies on weaker discovery signals.")
	}

	if supportsPublicTransport(executor.TransportPreferences) && task.DeliveryPreference == domain.DeliveryPreferencePublicFirst {
		score += 0.10
		reasons = append(reasons, "Transport path supports public response without DM approval.")
	}

	if strings.Contains(strings.ToLower(executor.Summary), "implementation") || contains(executor.ServiceModes, "rough_estimate") {
		score += 0.10
		reasons = append(reasons, "Executor profile signals implementation and first-response readiness.")
	}

	if overlap == 0 {
		risks = append(risks, "Capability overlap is weak, so routing confidence is lower.")
	}
	if !contains(executor.ServiceModes, "lead_intake") {
		risks = append(risks, "Lead-intake mode is not explicitly declared.")
	}
	if len(risks) == 0 {
		risks = append(risks, "Estimate quality may depend on clarifying project scope.")
	}

	return math.Min(score, 0.99), reasons, risks
}

func fitSummary(task domain.Task, executor domain.ExecutorPortfolio, score float64) string {
	if score >= 0.8 {
		return fmt.Sprintf("Strong fit for %s work.", summaryTags(task.TaskTags))
	}
	if score >= 0.6 {
		return fmt.Sprintf("Reasonable fit for %s work, with some uncertainty.", summaryTags(task.TaskTags))
	}
	return fmt.Sprintf("Weak fit for %s work.", summaryTags(task.TaskTags))
}

func summaryTags(tags []string) string {
	if len(tags) == 0 {
		return "general engineering"
	}
	if len(tags) == 1 {
		return tags[0]
	}
	return strings.Join(tags[:min(3, len(tags))], ", ")
}

func normalize(items []string) []string {
	out := make([]string, 0, len(items))
	for _, item := range items {
		item = strings.TrimSpace(strings.ToLower(item))
		if item != "" {
			out = append(out, item)
		}
	}
	return out
}

func intersectCount(a, b []string) int {
	set := make(map[string]struct{}, len(a))
	for _, item := range a {
		set[item] = struct{}{}
	}
	count := 0
	for _, item := range b {
		if _, ok := set[item]; ok {
			count++
		}
	}
	return count
}

func commonSlice(a, b []string) []string {
	set := make(map[string]struct{}, len(a))
	for _, item := range a {
		set[item] = struct{}{}
	}
	var out []string
	for _, item := range b {
		if _, ok := set[item]; ok {
			out = append(out, item)
		}
	}
	return out
}

func supportsPublicTransport(modes []domain.TransportMode) bool {
	for _, mode := range modes {
		if mode == domain.TransportModePublicComment || mode == domain.TransportModePublicPost {
			return true
		}
	}
	return false
}

func contains(values []string, needle string) bool {
	for _, value := range values {
		if strings.EqualFold(value, needle) {
			return true
		}
	}
	return false
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func humanizeExecutorID(id string) string {
	if strings.TrimSpace(id) == "" {
		return "This executor"
	}
	return strings.Title(strings.ReplaceAll(id, "_", " "))
}
