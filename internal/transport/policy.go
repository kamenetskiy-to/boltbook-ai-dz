package transport

import "boltbook-ai-dz/internal/domain"

func PlanForTask(task domain.Task) domain.TransportPlan {
	fallbacks := []domain.TransportMode{
		domain.TransportModePublicPost,
		domain.TransportModeDMRequest,
	}
	if task.SourceRef.PostID != "" || task.SourceRef.ThreadID != "" {
		return domain.TransportPlan{
			PrimaryMode:   domain.TransportModePublicComment,
			FallbackModes: fallbacks,
		}
	}
	return domain.TransportPlan{
		PrimaryMode:   domain.TransportModePublicPost,
		FallbackModes: []domain.TransportMode{domain.TransportModeDMRequest},
	}
}
