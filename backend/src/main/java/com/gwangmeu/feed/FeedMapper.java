package com.gwangmeu.feed;

import com.gwangmeu.feed.domain.Comment;
import com.gwangmeu.feed.domain.Post;
import com.gwangmeu.feed.dto.CommentDto;
import com.gwangmeu.feed.dto.PostDto;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface FeedMapper {

    PostDto toDto(Post post);

    CommentDto toDto(Comment comment);
}
