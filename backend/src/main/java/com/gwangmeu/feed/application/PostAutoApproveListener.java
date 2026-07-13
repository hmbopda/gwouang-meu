package com.gwangmeu.feed.application;

import com.gwangmeu.feed.domain.ModerationStatus;
import com.gwangmeu.feed.events.PostSubmittedEvent;
import com.gwangmeu.feed.infrastructure.PostRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Auto-approbation des publications soumises.
 *
 * <p>Le module de moderation IA prevu ({@link PostSubmittedEvent}) n'a jamais ete
 * branche : les posts restaient donc bloques en PENDING et n'apparaissaient jamais
 * dans le fil. Ce listener remplit ce vide en approuvant la publication une fois la
 * transaction de creation validee. La moderation reste possible a posteriori via le
 * signalement (flag) et la file de moderation existante.</p>
 *
 * <p>{@code @TransactionalEventListener(AFTER_COMMIT)} : ne se declenche qu'apres un
 * commit reel — donc jamais dans les tests transactionnels (qui rollback), ce qui
 * preserve les tests « createPost cree un post PENDING ». Desactivable via
 * {@code feed.auto-approve=false}.</p>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PostAutoApproveListener {

    private final PostRepository postRepository;

    @Value("${feed.auto-approve:true}")
    private boolean autoApprove;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onPostSubmitted(PostSubmittedEvent event) {
        if (!autoApprove) {
            return;
        }
        postRepository.findById(event.getPostId()).ifPresent(post -> {
            if (post.getModerationStatus() == ModerationStatus.PENDING) {
                post.setModerationStatus(ModerationStatus.APPROVED);
                postRepository.save(post);
                log.info("Post {} auto-approuve (fil communautaire)", event.getPostId());
            }
        });
    }
}
