package com.gwangmeu.feed;

import com.gwangmeu.feed.domain.Comment;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.dto.CommentDto;
import com.gwangmeu.feed.dto.PostDto;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface FeedMapper {

    // Les champs d'enrichissement (auteur, village, likedByMe) sont remplis
    // manuellement par le controleur ; ici on les ignore.
    @Mapping(target = "authorDisplayName", ignore = true)
    @Mapping(target = "authorAvatarUrl", ignore = true)
    @Mapping(target = "authorRole", ignore = true)
    @Mapping(target = "villageName", ignore = true)
    @Mapping(target = "likedByMe", ignore = true)
    PostDto toDto(Post post);

    @Mapping(target = "authorDisplayName", ignore = true)
    @Mapping(target = "authorAvatarUrl", ignore = true)
    @Mapping(target = "reactionCount", ignore = true)
    @Mapping(target = "likedByMe", ignore = true)
    CommentDto toDto(Comment comment);
}
