package com.gwangmeu.user;

import com.gwangmeu.user.dto.UserDto;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "id",              source = "id")
    @Mapping(target = "email",           source = "email")
    @Mapping(target = "displayName",     source = "displayName")
    @Mapping(target = "role",            source = "role")
    @Mapping(target = "country",         source = "country")
    @Mapping(target = "nativeLanguage",  source = "nativeLanguage")
    @Mapping(target = "bio",             source = "bio")
    @Mapping(target = "avatarUrl",       source = "avatarUrl")
    @Mapping(target = "originVillageId", source = "originVillageId")
    @Mapping(target = "createdAt",       source = "createdAt")
    UserDto toDto(User user);
}
